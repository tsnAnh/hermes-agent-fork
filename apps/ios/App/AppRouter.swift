import Observation

enum AppRoute: Hashable {
    case chat(botName: String)
    case botProfile(botName: String)
    case library(botName: String)
    case routines(botName: String)
    case slack(botName: String)
}

enum AppSheet: String, Identifiable {
    case settings

    var id: String { rawValue }
}

enum AppCapability: Hashable {
    case botProfile
    case shareAsTemplate
}

enum BotMenuAction: CaseIterable, Identifiable {
    case viewProfile
    case shareAsTemplate

    var id: Self { self }
}

@MainActor
@Observable
final class AppRouter {
    var path: [AppRoute] = []
    var sheet: AppSheet?
    private(set) var capabilities: Set<AppCapability>
    @ObservationIgnored private var shareAsTemplateHandler: ((String) -> Void)?

    init(capabilities: Set<AppCapability> = []) {
        self.capabilities = capabilities
    }

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func present(_ sheet: AppSheet) {
        self.sheet = sheet
    }

    func dismissSheet() {
        sheet = nil
    }

    func popToRoot() {
        path.removeAll()
    }

    func supports(_ action: BotMenuAction) -> Bool {
        switch action {
        case .viewProfile: capabilities.contains(.botProfile)
        case .shareAsTemplate: capabilities.contains(.shareAsTemplate)
        }
    }

    func registerShareAsTemplate(_ handler: @escaping (String) -> Void) {
        shareAsTemplateHandler = handler
        capabilities.insert(.shareAsTemplate)
    }

    func perform(_ action: BotMenuAction, botName: String) {
        guard supports(action) else { return }
        switch action {
        case .viewProfile: push(.botProfile(botName: botName))
        case .shareAsTemplate: shareAsTemplateHandler?(botName)
        }
    }

    @discardableResult
    func openChat(sessionID: String, in roster: RosterModel) -> Bool {
        guard let name = roster.botName(forSessionID: sessionID) else { return false }
        if path.last != .chat(botName: name) { path = [.chat(botName: name)] }
        return true
    }
}
