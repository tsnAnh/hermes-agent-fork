import HermesClient
import HermesDesign
import SwiftUI

@main
struct HermesBotsApp: App {
    @State private var model: ConnectionModel
    @State private var roster: RosterModel
    @State private var offers: ReachOfferModel
    @State private var router: AppRouter
    @State private var appearance: AppearanceStore
    @State private var consent: DeviceConsentPresenter
    @State private var hostPool: DeviceHostPool
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let model = ConnectionModel.live()
        _model = State(initialValue: model)
        let roster = RosterModel(connection: model)
        _roster = State(initialValue: roster)
        let router = AppRouter()
        _router = State(initialValue: router)
        _appearance = State(initialValue: AppearanceStore())
        let consent = DeviceConsentPresenter { profile in
            roster.bot(named: profile)?.displayName ?? roster.hero?.displayName ?? profile
        }
        _consent = State(initialValue: consent)
        _hostPool = State(initialValue: DeviceHostPool(connection: model, consent: consent))
        _offers = State(initialValue: ReachOfferModel(presence: model.presence) { sessionID in
            router.openChat(sessionID: sessionID, in: roster)
        })
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, roster: roster, router: router, hostPool: hostPool)
                .overlay { ReachOfferOverlay(model: offers) }
                .deviceConsentAlert(consent)
                .hermesTheme(mode: appearance.mode, botAccent: roster.hero?.accent)
                .task { await model.restore() }
                .task { await offers.listen() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { Task { await model.restore() } }
                }
                .onChange(of: model.phase) { _, phase in
                    if phase == .signedOut { Task { await hostPool.reset() } }
                }
                .onChange(of: scenePhase, initial: true) { _, phase in
                    model.report(attention: ReachAttention(sceneIsActive: phase == .active))
                }
        }
    }
}

struct RootView: View {
    let model: ConnectionModel
    let roster: RosterModel
    @Bindable var router: AppRouter
    let hostPool: DeviceHostPool

    var body: some View {
        switch model.phase {
        case .connected:
            NavigationStack(path: $router.path) {
                RosterView(roster: roster, connection: model) { router.present(.settings) }
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .chat(let name):
                            if let bot = roster.bot(named: name) {
                                ChatView(model: ChatModel(bot: bot, connection: model, roster: roster))
                            }
                        }
                    }
            }
            .task { await roster.runLive() }
            .task {
                await hostPool.resumeSavedHosts()
                if ProcessInfo.processInfo.arguments.contains(ConnectAppsLaunch.argument) { router.presentConnectApps() }
            }
            .sheet(item: $router.sheet) { sheet in
                switch sheet {
                case .settings:
                    SettingsSheet(model: model) { router.dismissSheet() }
                case .connectApps:
                    ConnectAppsSheet(
                        model: ConnectAppsModel(
                            connection: model,
                            pool: hostPool,
                            profile: router.connectAppsProfile,
                            botName: roster.displayName(forProfile: router.connectAppsProfile),
                            browser: WebAuthenticationBrowser()
                        )
                    ) { router.dismissSheet() }
                }
            }
        case .connecting:
            ProgressView("Connecting")
                .accessibilityIdentifier("connectingIndicator")
        default:
            ConnectionView(model: model)
        }
    }
}
