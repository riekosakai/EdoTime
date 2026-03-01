import Foundation

enum TimeFormatters {
    static let hm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static let hms: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

enum TimeText {
    static func hhmm(_ date: Date) -> String {
        TimeFormatters.hm.string(from: date)
    }

    static func remaining(_ interval: TimeInterval) -> String {
        let sec = max(0, Int(interval.rounded(.down)))
        let minutes = sec / 60
        let seconds = sec % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func minutes(_ interval: TimeInterval) -> String {
        "\(Int((interval / 60.0).rounded()))分"
    }
}

enum DateClamp {
    static func clamp(_ value: Date, min lower: Date, max upper: Date) -> Date {
        if value < lower { return lower }
        if value > upper { return upper }
        return value
    }

    static func clampedRatio(value: Date, start: Date, end: Date) -> Double {
        guard end > start else { return 0 }
        let total = end.timeIntervalSince(start)
        let v = DateClamp.clamp(value, min: start, max: end)
        return v.timeIntervalSince(start) / total
    }
}
