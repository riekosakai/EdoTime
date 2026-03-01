import Foundation

enum EdoSegmentType: String, Codable {
    case day
    case night

    var japaneseLabel: String {
        switch self {
        case .day: return "昼"
        case .night: return "夜"
        }
    }
}

struct GeoPoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

struct SolarTimes: Equatable {
    let sunrise: Date
    let sunset: Date
    let nextSunrise: Date
    let yesterdaySunset: Date
}

struct EdoSegment: Identifiable, Equatable {
    let type: EdoSegmentType
    let index: Int
    let start: Date
    let end: Date
    let length: TimeInterval

    var id: String {
        "\(type.rawValue)-\(index)-\(start.timeIntervalSince1970)"
    }

    var label: String {
        "\(type.japaneseLabel)の第\(index)刻"
    }
}

struct EdoTimeSnapshot {
    let dayStart: Date
    let dayEnd: Date
    let solarTimes: SolarTimes
    let dayKoku: TimeInterval
    let nightKoku: TimeInterval
    let boundaries: [Date]
    let currentSegment: EdoSegment
    let remainingToNextBoundary: TimeInterval
    let displaySegments: [EdoSegment]
}
