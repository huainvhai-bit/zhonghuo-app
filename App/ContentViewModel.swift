//
//  ContentViewModel.swift
//  终活
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
        case unauthorized
        case networkError
        case serverError
    }

    @Published var selectedTab = 0
    @Published var showingFamilyGuard = false
    @Published var forceLogout = false
    @Published var isCheckingAuth = true
    @Published var showingLogoutAlert = false
    @Published var logoutReason = ""
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
                if userManager.isLoggedIn {
                    userManager.performAutoSignIn()
                }
            }
        }
    }

    func openPendingUpdateIfNeeded() {
        let showing = UserDefaults.standard.bool(forKey: "showingUpdateAlert")
        guard showing, !showingUpdateAlert else { return }

        updateVersion = UserDefaults.standard.string(forKey: "pendingUpdateVersion") ?? ""
        updateUrl = UserDefaults.standard.string(forKey: "pendingUpdateUrl") ?? ""
        let forceVersion = UserDefaults.standard.string(forKey: "pendingForceUpdateVersion") ?? ""
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

        isForceUpdate = isVersionNewerOrEqual(forceVersion, than: currentVersion)
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

    func handleOpenFamilyGuard() {
        showingFamilyGuard = true
    }

    func handleSwitchToTab(_ tabIndex: Int) {
        selectedTab = tabIndex
    }

    func checkMaintenanceMode() async {
        await dataManager.loadSystemConfig()
        let config = dataManager.systemConfig
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
            if validationResult == .unauthorized {
                userManager.logout()
                hasPersistentSession = false
                isCheckingAuth = false
                return
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
                       let user = dataObj["user"] as? [String: Any],
                       let userId = user["id"] as? String {
                        print("✅ validateToken: userId=\(userId)")
                        return .success
                    } else if let responseString = String(data: data, encoding: .utf8),
                              responseString.contains("未授权") || responseString.contains("账号不存在") || responseString.contains("登录已过期") {
                        return .unauthorized
                    } else if let errors = json["errors"] as? [[String: Any]] {
                        print("❌ validateToken: GraphQL errors: \(errors)")
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

    private func isVersionNewer(_ v1: String, than v2: String) -> Bool {
        let v1Components = v1.split(separator: ".").compactMap { Int($0) }
        let v2Components = v2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(v1Components.count, v2Components.count) {
            let v1Part = i < v1Components.count ? v1Components[i] : 0
            let v2Part = i < v2Components.count ? v2Components[i] : 0

            if v1Part > v2Part {
                return true
            } else if v1Part < v2Part {
                return false
            }
        }

        return false
    }

    private func isVersionNewerOrEqual(_ v1: String, than v2: String) -> Bool {
        if v1 == v2 {
            return true
        }
        return isVersionNewer(v1, than: v2)
    }
}
