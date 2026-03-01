import Foundation

struct EdoTimeService {
    private let solarCalculator = SolarCalculator()

    func compute(now: Date, location: GeoPoint, timeZone: TimeZone = .current) throws -> EdoTimeSnapshot {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let dayStart = calendar.startOfDay(for: now)
        guard
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: dayStart),
            let yesterday = calendar.date(byAdding: .day, value: -1, to: dayStart)
        else {
            throw SolarCalculationError.invalidDate
        }

        let todayTimes: (sunrise: Date, sunset: Date)
        let tomorrowTimes: (sunrise: Date, sunset: Date)
        let yesterdayTimes: (sunrise: Date, sunset: Date)

        do {
            todayTimes = try solarCalculator.sunriseSunset(
                for: dayStart,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZone: timeZone
            )
            tomorrowTimes = try solarCalculator.sunriseSunset(
                for: tomorrow,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZone: timeZone
            )
            yesterdayTimes = try solarCalculator.sunriseSunset(
                for: yesterday,
                latitude: location.latitude,
                longitude: location.longitude,
                timeZone: timeZone
            )
        } catch {
            print("❌ EdoTimeService.compute sunriseSunset failed: \(type(of: error)) / \(error)")
            print("   now=\(now) dayStart=\(dayStart) tz=\(timeZone.identifier)")
            print("   lat=\(location.latitude) lon=\(location.longitude)")
            throw error
        }

        let solar = SolarTimes(
            sunrise: todayTimes.sunrise,
            sunset: todayTimes.sunset,
            nextSunrise: tomorrowTimes.sunrise,
            yesterdaySunset: yesterdayTimes.sunset
        )

        let dayLen = solar.sunset.timeIntervalSince(solar.sunrise)
        let nightLen = solar.nextSunrise.timeIntervalSince(solar.sunset)

        // ここだけ追加：落ちるときの原因が一瞬で分かる
        if dayLen <= 0 || nightLen <= 0 {
            print("❌ invalid day/night length")
            print("   sunrise=\(solar.sunrise) sunset=\(solar.sunset) nextSunrise=\(solar.nextSunrise) yesterdaySunset=\(solar.yesterdaySunset)")
            print("   dayLen=\(dayLen) nightLen=\(nightLen) tz=\(timeZone.identifier)")
            throw SolarCalculationError.invalidDate
        }

        let dayKoku = dayLen / 6.0
        let nightKoku = nightLen / 6.0

        let daySegments = buildSegments(type: .day, baseStart: solar.sunrise, length: dayKoku)
        let nightSegmentsForDisplay = buildSegments(type: .night, baseStart: solar.sunset, length: nightKoku)

        let displaySegments = daySegments + nightSegmentsForDisplay

        let currentSegment: EdoSegment
        if now >= solar.sunrise && now < solar.sunset {
            currentSegment = segment(for: now, type: .day, start: solar.sunrise, length: dayKoku)
        } else if now >= solar.sunset && now < solar.nextSunrise {
            currentSegment = segment(for: now, type: .night, start: solar.sunset, length: nightKoku)
        } else {
            let previousNightLen = solar.sunrise.timeIntervalSince(solar.yesterdaySunset)
            let previousNightKoku = previousNightLen / 6.0
            currentSegment = segment(for: now, type: .night, start: solar.yesterdaySunset, length: previousNightKoku)
        }

        var boundaries = [Date]()
        boundaries.append(contentsOf: segmentBoundaries(start: solar.sunrise, length: dayKoku))
        boundaries.append(contentsOf: segmentBoundaries(start: solar.sunset, length: nightKoku))

        let uniqueSortedBoundaries = Array(Set(boundaries.map { $0.timeIntervalSince1970 }))
            .sorted()
            .map { Date(timeIntervalSince1970: $0) }

        let remaining = max(0, currentSegment.end.timeIntervalSince(now))

        return EdoTimeSnapshot(
            dayStart: dayStart,
            dayEnd: tomorrow,
            solarTimes: solar,
            dayKoku: dayKoku,
            nightKoku: nightKoku,
            boundaries: uniqueSortedBoundaries,
            currentSegment: currentSegment,
            remainingToNextBoundary: remaining,
            displaySegments: displaySegments
        )
    }

    private func segment(for now: Date, type: EdoSegmentType, start: Date, length: TimeInterval) -> EdoSegment {
        let elapsed = max(0, now.timeIntervalSince(start))
        let raw = Int(floor(elapsed / length)) + 1
        let idx = min(max(raw, 1), 6)
        let segmentStart = start.addingTimeInterval(Double(idx - 1) * length)
        let segmentEnd = segmentStart.addingTimeInterval(length)
        return EdoSegment(type: type, index: idx, start: segmentStart, end: segmentEnd, length: length)
    }

    private func buildSegments(type: EdoSegmentType, baseStart: Date, length: TimeInterval) -> [EdoSegment] {
        (1...6).map { i in
            let start = baseStart.addingTimeInterval(Double(i - 1) * length)
            let end = baseStart.addingTimeInterval(Double(i) * length)
            return EdoSegment(type: type, index: i, start: start, end: end, length: length)
        }
    }

    private func segmentBoundaries(start: Date, length: TimeInterval) -> [Date] {
        (0...6).map { i in
            start.addingTimeInterval(Double(i) * length)
        }
    }
}
