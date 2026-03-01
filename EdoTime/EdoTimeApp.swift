import SwiftUI

@main
struct EdoTimeApp: App {

    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: viewModel)
        }
    }
}
