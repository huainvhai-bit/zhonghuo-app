//
//  ContentViewModel.swift
//  安心助手
//
//  根容器状态与生命周期管理
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class ContentViewModel: ObservableObject {
    enum ValidateTokenResult {
        case success
        /// 令牌无效或会话过期（非风控封号）
        case unauthorized
        /// 封号 / 封 IP 或会话被顶替：需清空登录并弹出说明（标题见 `ForcedLogoutAlertKind`）
        case forcedLogout(kind: BackendSecurityPolicy.ForcedLogoutAlertKind, message: String)

        case networkError
        case serverError
    }

    @Published var selectedTab = 0
    @Published var showingFamilyGuard = false
    @Published var forceLogout = false
    @Published var isCheckingAuth = true
    @Published var showingLogoutAlert = false
    @Published var logoutReason = ""
    @Published var showingPolicyViolationAlert = false
    /// 弹框正文（封号 / 风控 / 其他设备顶替）
    @Published var policyViolationMessage = ""
    /// 与 `policyViolationMessage` 配套的标题（封号类 vs 已在其他设备登录）
    @Published var forcedLogoutAlertKind: BackendSecurityPolicy.ForcedLogoutAlertKind = .policyRestriction
    @Published var showingUpdateAlert = false
    @Published var updateVersion = ""
    @Published var updateUrl = ""
    @Published var isForceUpdate = false
    @Published var isMaintenanceMode = false
    @Published var maintenanceMessage = "系统维护中，请稍后再试"
    @Published var hasPersistentSession = false

    private let dataManager = DataManager.shared
    private let userManager = UserManager.shared
    private var observers: [NSObjectProtocol] = []
    private var updateTimer: Timer?
    private var didStart = false

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        updateTimer?.invalidate()
    }

    func start() {
        guard !didStart else { return }
        didStart = true

        registerObservers()
        syncPersistentSessionState()

        Task {
            await checkMaintenanceMode()
        }

        Task {
            await checkLoginStatus()
        }
    }

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active {
            NotificationCenter.default.post(name: NSNotification.Name("SceneDidBecomeActive"), object: nil)
            syncPersistentSessionState()

            Task {
                await checkLoginStatus()
                await ForceUpdateGate.shared.refreshFromRemote()
                if userManager.isLoggedIn {
                    userManager.performAutoSignIn()
                }
            }
        }
    }

    func openPendingUpdateIfNeeded() {
        if ForceUpdateGate.shared.blocksInteraction {
            return
        }
        let showing = UserDefaults.standard.bool(forKey: "showingUpdateAlert")
        guard showing, !showingUpdateAlert else { return }

        updateVersion = UserDefaults.standard.string(forKey: "pendingUpdateVersion") ?? ""
        updateUrl = UserDefaults.standard.string(forKey: "pendingUpdateUrl") ?? ""
        // 强更仅用全屏挡板；此处弹窗始终为可选更新（可点「稍后」）
        isForceUpdate = false

        showingUpdateAlert = true
        UserDefaults.standard.set(false, forKey: "showingUpdateAlert")
    }

    func openUpdateURL() {
        guard !updateUrl.isEmpty, let url = URL(string: updateUrl) else { return }
        UIApplication.shared.open(url)
    }

    func handleUserDidLogin() {
        syncPersistentSessionState()
        Task {
            await checkLoginStatus()
        }
    }

    func handleForceLogout() {
        forceLogout = true
        hasPersistentSession = false
        isCheckingAuth = false
    }

    func handleUserDidLogout() {
        forceLogout = true
        hasPersistentSession = false
        isCheckingAuth = false
    }

    /// 封号 / IP 风控 / 会话被顶替：清空会话并弹框说明
    func handlePolicyViolation(_ reason: String, kind: BackendSecurityPolicy.ForcedLogoutAlertKind = .policyRestriction) {
        forcedLogoutAlertKind = kind
        policyViolationMessage = reason.isEmpty
            ? BackendSecurityPolicy.userFacingMessage(for: "ACCOUNT_BANNED:")
            : reason
        showingPolicyViolationAlert = true
        userManager.logout()
        hasPersistentSession = false
        isCheckingAuth = false
        forceLogout = true
    }

    func handleOpenFamilyGuard() {
        guard AppConfig.showsFamilyFeatures else {
            print("👨‍👩‍👧 送审版已隐藏添加页面入口")
            return
        }
        showingFamilyGuard = true
    }

    func handleSwitchToTab(_ tabIndex: Int) {
        selectedTab = tabIndex
    }

    func checkMaintenanceMode() async {
        await dataManager.loadSystemConfig()
        let config = dataManager.systemConfig
        ForceUpdateGate.shared.refresh(from: config)
        if config.appMaintenanceMode {
            isMaintenanceMode = true
            maintenanceMessage = config.appMaintenanceMessage
        }
    }

    func checkLoginStatus() async {
        forceLogout = false
        userManager.loadUser()
        let hasToken = KeychainManager.shared.getToken() != nil
        hasPersistentSession = hasToken

        if hasToken {
            let validationResult = await validateToken()
            switch validationResult {
            case .forcedLogout(let kind, let message):
                handlePolicyViolation(message, kind: kind)
                return
            case .unauthorized:
                userManager.logout()
                hasPersistentSession = false
                isCheckingAuth = false
                return
            case .networkError, .serverError:
                break
            case .success:
                break
            }

            forceLogout = false
        }

        isCheckingAuth = false
    }

    func validateToken() async -> ValidateTokenResult {
        guard let token = KeychainManager.shared.getToken(), !token.isEmpty else {
            return .unauthorized
        }

        guard !DataManager.apiURL.isEmpty else {
            return .networkError
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)

        do {
            let query = """
            query {
                user {
                    id
                    name
                    phone
                }
            }
            """

            var request = URLRequest(url: URL(string: "\(DataManager.apiURL)/api/graphql.php")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = ["query": query]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await session.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200:
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        if let responseString = String(data: data, encoding: .utf8),
                           (responseString.contains("Parse error") || responseString.contains("Fatal error") || responseString.contains("Warning")) {
                            return .serverError
                        }
                        return .serverError
                    }

                    if let dataObj = json["data"] as? [String: Any],
                       let userValue = dataObj["user"] {
                        if userValue is NSNull {
                            print("⚠️ validateToken: 服务端返回 user = null")
                            return .unauthorized
                        }
                        
                        if let user = userValue as? [String: Any],
                           let userId = user["id"] as? String {
                            print("✅ validateToken: userId=\(userId)")
                            return .success
                        }
                    }

                    // 容错：整块 JSON / 报错文本里识别风控前缀
                    if let responseString = String(data: data, encoding: .utf8),
                       let raw = extractFirstBannedMessage(from: responseString) {
                        return .forcedLogout(
                            kind: BackendSecurityPolicy.ForcedLogoutAlertKind(rawServerMessage: raw),
                            message: BackendSecurityPolicy.userFacingMessage(for: raw)
                        )
                    }
                    if let responseString = String(data: data, encoding: .utf8),
                              responseString.contains("未授权") || responseString.contains("账号不存在") || responseString.contains("登录已过期") {
                        return .unauthorized
                    } else                     if let errors = json["errors"] as? [[String: Any]] {
                        print("❌ validateToken: GraphQL errors: \(errors)")
                        for dict in errors {
                            if let m = dict["message"] as? String, BackendSecurityPolicy.requiresForcedLogoutBanner(m) {
                                let kind = BackendSecurityPolicy.ForcedLogoutAlertKind(rawServerMessage: m)
                                return .forcedLogout(kind: kind, message: BackendSecurityPolicy.userFacingMessage(for: m))
                            }
                        }
                        let errorText = errors.compactMap { $0["message"] as? String }.joined(separator: " | ")
                        if errorText.contains("未授权") || errorText.contains("账号不存在") || errorText.contains("登录已过期") {
                            return .unauthorized
                        }
                        return .serverError
                    } else {
                        return .serverError
                    }
                case 401, 403:
                    return .unauthorized
                case 404:
                    return .serverError
                case 500, 502, 503, 504:
                    return .serverError
                case 400, 405, 408, 429:
                    return .networkError
                default:
                    return .serverError
                }
            }
            return .networkError
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .timedOut, .cannotFindHost, .cannotConnectToHost:
                return .networkError
            default:
                return .networkError
            }
        } catch {
            return .networkError
        }
    }

    private func registerObservers() {
        observers.append(
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ForceLogout"), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.handleForceLogout()
                }
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(forName: BackendSecurityPolicy.violationNotificationName, object: nil, queue: .main) { [weak self] note in
                Task { @MainActor in
                    let rawMsg = note.userInfo?["message"] as? String ?? ""
                    let kindValue = note.userInfo?[BackendSecurityPolicy.forcedLogoutKindUserInfoKey] as? String
                    let kind = BackendSecurityPolicy.ForcedLogoutAlertKind(rawValue: kindValue ?? "")
                        ?? .policyRestriction
                    self?.handlePolicyViolation(rawMsg, kind: kind)
                }
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(forName: NSNotification.Name("UserDidLogout"), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.handleUserDidLogout()
                }
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(forName: NSNotification.Name("UserDidLogin"), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.handleUserDidLogin()
                }
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(forName: NSNotification.Name("OpenFamilyGuard"), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.handleOpenFamilyGuard()
                }
            }
        )

        observers.append(
            NotificationCenter.default.addObserver(forName: NSNotification.Name("SwitchToTab"), object: nil, queue: .main) { [weak self] notification in
                if let tabIndex = notification.userInfo?["tab"] as? Int {
                    Task { @MainActor in
                        self?.handleSwitchToTab(tabIndex)
                    }
                }
            }
        )

        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.openPendingUpdateIfNeeded()
            }
        }
    }

    private func syncPersistentSessionState() {
        hasPersistentSession = KeychainManager.shared.getToken() != nil
    }

    /// 从整块 HTTP 正文中截取首条风控报错（容错 JSON 结构异常时有文本线索）
    private func extractFirstBannedMessage(from responseString: String) -> String? {
        for pref in ["ACCOUNT_BANNED:", "IP_BANNED_LOGIN:", "IP_BANNED_REGISTER:", BackendSecurityPolicy.sessionSupersededPrefix] {
            guard let range = responseString.range(of: pref) else { continue }
            let rest = responseString[range.lowerBound...]
            let firstLine = rest.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? String(rest)
            let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ",\"")))
            if BackendSecurityPolicy.isRestrictedServerMessage(trimmed)
                || trimmed.contains(BackendSecurityPolicy.sessionSupersededPrefix) {
                return trimmed
            }
        }
        return nil
    }
}
