import Foundation

enum SolarCalculationError: LocalizedError {
    case neverRises
    case neverSets
    case invalidDate

    var errorDescription: String? {
        switch self {
        case .neverRises:
            return "この地点・日付では日の出を計算できません。"
        case .neverSets:
            return "この地点・日付では日の入りを計算できません。"
        case .invalidDate:
            return "日付の計算に失敗しました。"
        }
    }
}

struct SolarCalculator {
    private let zenith = 90.833

    // NOAA Solar Calculator approach (offline).
    func sunriseSunset(
        for date: Date,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone
    ) throws -> (sunrise: Date, sunset: Date) {

        // ローカル暦で YYYY-MM-DD を確定
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone

        let comps = cal.dateComponents([.year, .month, .day], from: date)
        guard let year = comps.year, let month = comps.month, let day = comps.day else {
            print("❌ invalidDate: date=\(date), tz=\(timeZone.identifier), comps=\(comps)")
            throw SolarCalculationError.invalidDate
        }

        // ローカル日付の 00:00（この日を基準に Date を作る）
        guard let localMidnight = cal.date(from: DateComponents(year: year, month: month, day: day, hour: 0, minute: 0, second: 0)) else {
            print("❌ invalidDate(localMidnight): y=\(year) m=\(month) d=\(day) tz=\(timeZone.identifier)")
            throw SolarCalculationError.invalidDate
        }

        let dayOfYear = cal.ordinality(of: .day, in: .year, for: localMidnight) ?? 1

        // NOAA が返すのは「UTC時刻(0-24h)」
        let sunriseUTCHour = try solarUTCHour(
            dayOfYear: dayOfYear,
            latitude: latitude,
            longitude: longitude,
            isSunrise: true
        )
        let sunsetUTCHour = try solarUTCHour(
            dayOfYear: dayOfYear,
            latitude: latitude,
            longitude: longitude,
            isSunrise: false
        )

        // ✅ ここが重要：UTC hour を「ローカル時刻 hour」に変換して、
        // localMidnight から足して Date を作る（UTC日付跨ぎ問題を潰す）
        let offsetHours = Double(timeZone.secondsFromGMT(for: localMidnight)) / 3600.0

        let sunriseLocalHour = normalizeHours(Double(sunriseUTCHour) + offsetHours)
        let sunsetLocalHour  = normalizeHours(Double(sunsetUTCHour)  + offsetHours)

        let sunrise = localMidnight.addingTimeInterval(sunriseLocalHour * 3600)
        let sunset  = localMidnight.addingTimeInterval(sunsetLocalHour  * 3600)

        return (sunrise, sunset)
    }

    private func solarUTCHour(dayOfYear: Int, latitude: Double, longitude: Double, isSunrise: Bool) throws -> TimeInterval {
        let lngHour = longitude / 15.0
        let baseHour = isSunrise ? 6.0 : 18.0
        let t = Double(dayOfYear) + ((baseHour - lngHour) / 24.0)

        let meanAnomaly = (0.9856 * t) - 3.289

        let trueLongitude = normalizeDegrees(
            meanAnomaly
            + (1.916 * sin(deg2rad(meanAnomaly)))
            + (0.020 * sin(deg2rad(2 * meanAnomaly)))
            + 282.634
        )

        var rightAscension = rad2deg(atan(0.91764 * tan(deg2rad(trueLongitude))))
        rightAscension = normalizeDegrees(rightAscension)

        let lQuadrant  = floor(trueLongitude / 90.0) * 90.0
        let raQuadrant = floor(rightAscension / 90.0) * 90.0
        rightAscension += (lQuadrant - raQuadrant)
        rightAscension /= 15.0

        let sinDec = 0.39782 * sin(deg2rad(trueLongitude))
        let cosDec = cos(asin(sinDec))

        let cosH = (
            cos(deg2rad(zenith))
            - (sinDec * sin(deg2rad(latitude)))
        ) / (cosDec * cos(deg2rad(latitude)))

        if cosH > 1 { throw isSunrise ? SolarCalculationError.neverRises : SolarCalculationError.neverSets }
        if cosH < -1 { throw isSunrise ? SolarCalculationError.neverRises : SolarCalculationError.neverSets }

        let hourAngle: Double = isSunrise
            ? 360.0 - rad2deg(acos(cosH))
            : rad2deg(acos(cosH))

        let h = hourAngle / 15.0
        let localMeanTime = h + rightAscension - (0.06571 * t) - 6.622
        let utc = normalizeHours(localMeanTime - lngHour)
        return utc
    }

    private func deg2rad(_ value: Double) -> Double { value * .pi / 180.0 }
    private func rad2deg(_ value: Double) -> Double { value * 180.0 / .pi }

    private func normalizeDegrees(_ value: Double) -> Double {
        let mod = value.truncatingRemainder(dividingBy: 360.0)
        return mod >= 0 ? mod : mod + 360.0
    }

    private func normalizeHours(_ value: Double) -> Double {
        let mod = value.truncatingRemainder(dividingBy: 24.0)
        return mod >= 0 ? mod : mod + 24.0
    }
}
