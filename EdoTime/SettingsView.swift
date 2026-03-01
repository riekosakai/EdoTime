import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Form {
            Section("位置情報") {
                Toggle("現在地を使う", isOn: $viewModel.useCurrentLocation)

                if viewModel.useCurrentLocation {
                    Button("位置情報を再取得") {
                        viewModel.refreshLocation()
                    }
                } else {
                    TextField("緯度 (例: 35.681236)", text: $viewModel.manualLatitudeText)
                        .keyboardType(.decimalPad)
                    TextField("経度 (例: 139.767125)", text: $viewModel.manualLongitudeText)
                        .keyboardType(.decimalPad)

                    Button("保存") {
                        viewModel.saveManualLocation()
                    }
                }
            }

            Section("有効な座標") {
                Text("緯度: \(String(format: "%.6f", viewModel.effectiveLocation.latitude))")
                Text("経度: \(String(format: "%.6f", viewModel.effectiveLocation.longitude))")
            }
        }
        .navigationTitle("設定")
    }
}
