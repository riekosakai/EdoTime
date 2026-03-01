import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel

    // 今日の日付文字列
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter.string(from: viewModel.now)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // 👇 ここが追加した日付表示
                // 👇 日付（目立つ版）
                Text(todayString)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("地点: \(viewModel.locationName)")
                    Text("日の出: \(viewModel.sunriseText)")
                    Text("日の入: \(viewModel.sunsetText)")
                    Text("現在: \(viewModel.currentSegmentLabel)")
                        .font(.headline)
                    Text("次の刻まで: \(viewModel.remainingText)")
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let snapshot = viewModel.snapshot {
                    TimelineViewPanel(snapshot: snapshot, now: viewModel.now)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                NavigationLink("時刻表", destination: TimetableView(viewModel: viewModel))
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                NavigationLink("タイムライン", destination: TimelineScreen(viewModel: viewModel))
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                NavigationLink("設定", destination: SettingsView(viewModel: viewModel))
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                Spacer()
            }
            .padding()
            .navigationTitle("江戸時間")
        }
    }
}
