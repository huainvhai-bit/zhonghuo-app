//
//  AppCaptchaService.swift
//  终活
//
//  App 图形验证码加载服务
//

import Foundation
import UIKit

@MainActor
final class AppCaptchaService: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let purpose: String

    init(purpose: String) {
        self.purpose = purpose
    }

    func reload() {
        Task { await loadCaptcha() }
    }

    func loadCaptcha() async {
        isLoading = true
        errorMessage = nil
        image = nil
        defer { isLoading = false }

        do {
            let baseURL = resolveBaseURL()
            let purposeValue = purpose.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? purpose
            guard let url = URL(string: "\(baseURL)/api/captcha.php?purpose=\(purposeValue)&t=\(UUID().uuidString)") else {
                throw NSError(domain: "Invalid URL", code: -1, userInfo: [NSLocalizedDescriptionKey: "验证码地址无效"])
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 15

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "CaptchaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "验证码加载失败，请稍后重试"])
            }

            guard let image = UIImage(data: data) else {
                throw NSError(domain: "CaptchaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "验证码图片解析失败"])
            }

            self.image = image
        } catch {
            self.errorMessage = error.localizedDescription
            self.image = nil
        }
    }

    private func resolveBaseURL() -> String {
        let rawBaseURL = UserDefaults.standard.string(forKey: "lastUsedBaseURL") ?? "zhonghuo.zhonghuo.xyz"
        return NetworkUtils.normalizeBaseURL(rawBaseURL)
    }
}
