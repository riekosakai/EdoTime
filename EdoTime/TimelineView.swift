import SwiftUI

struct TimelineScreen: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        ScrollView {
            if let snapshot = viewModel.snapshot {
                TimelineViewPanel(snapshot: snapshot, now: viewModel.now)
                    .padding()
            } else {
                Text("データを表示できません")
                    .padding()
            }
        }
        .navigationTitle("タイムライン")
    }
}

struct TimelineViewPanel: View {
    let snapshot: EdoTimeSnapshot
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(snapshot.currentSegment.label)
                .font(.headline)

            GeometryReader { geo in
                let width = geo.size.width
                let barHeight: CGFloat = 28

                let sunriseRatio = DateClamp.clampedRatio(value: snapshot.solarTimes.sunrise, start: snapshot.dayStart, end: snapshot.dayEnd)
                let sunsetRatio = DateClamp.clampedRatio(value: snapshot.solarTimes.sunset, start: snapshot.dayStart, end: snapshot.dayEnd)
                let nowRatio = DateClamp.clampedRatio(value: now, start: snapshot.dayStart, end: snapshot.dayEnd)

                let sunriseX = width * sunriseRatio
                let sunsetX = width * sunsetRatio
                let nowX = width * nowRatio

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.indigo.opacity(0.22))
                        .frame(height: barHeight)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.yellow.opacity(0.6))
                        .frame(width: max(0, sunsetX - sunriseX), height: barHeight)
                        .offset(x: sunriseX)

                    ForEach(snapshot.boundaries, id: \.self) { boundary in
                        if boundary >= snapshot.dayStart && boundary <= snapshot.dayEnd {
                            let x = width * DateClamp.clampedRatio(value: boundary, start: snapshot.dayStart, end: snapshot.dayEnd)
                            Path { path in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: barHeight))
                            }
                            .stroke(Color.primary.opacity(0.7), lineWidth: 1)
                        }
                    }

                    Path { path in
                        path.move(to: CGPoint(x: nowX, y: -8))
                        path.addLine(to: CGPoint(x: nowX, y: barHeight + 10))
                    }
                    .stroke(Color.red, lineWidth: 2)

                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .position(x: nowX, y: -4)

                    HStack {
                        Text("00:00")
                        Spacer()
                        Text("24:00")
                    }
                    .font(.caption)
                    .offset(y: barHeight + 8)

                    Text(TimeText.hhmm(snapshot.solarTimes.sunrise))
                        .font(.caption2)
                        .offset(x: min(max(sunriseX - 14, 0), max(width - 40, 0)), y: barHeight + 24)

                    Text(TimeText.hhmm(snapshot.solarTimes.sunset))
                        .font(.caption2)
                        .offset(x: min(max(sunsetX - 14, 0), max(width - 40, 0)), y: barHeight + 24)
                }
            }
            .frame(height: 76)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
