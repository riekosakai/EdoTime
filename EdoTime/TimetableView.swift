import SwiftUI

struct TimetableView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        List {
            if let snapshot = viewModel.snapshot {
                Section("昼") {
                    ForEach(snapshot.displaySegments.filter { $0.type == .day }) { segment in
                        row(for: segment, current: snapshot.currentSegment)
                    }
                }

                Section("夜") {
                    ForEach(snapshot.displaySegments.filter { $0.type == .night }) { segment in
                        row(for: segment, current: snapshot.currentSegment)
                    }
                }

                Section("刻の長さ") {
                    Text("昼の一刻: \(viewModel.dayKokuText)")
                    Text("夜の一刻: \(viewModel.nightKokuText)")
                }
            } else {
                Text("時刻表を表示できません")
            }
        }
        .navigationTitle("時刻表")
    }

    @ViewBuilder
    private func row(for segment: EdoSegment, current: EdoSegment) -> some View {
        HStack {
            Text(segment.label)
            Spacer()
            Text(TimeText.hhmm(segment.start))
                .monospacedDigit()
        }
        .listRowBackground(
            current.type == segment.type && current.index == segment.index
            ? Color.yellow.opacity(0.25)
            : Color.clear
        )
    }
}
