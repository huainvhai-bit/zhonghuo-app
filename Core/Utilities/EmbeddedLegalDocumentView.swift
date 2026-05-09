//
//  EmbeddedLegalDocumentView.swift
//  安伴助手
//
//  App 内嵌法务文档查看器
//

import SwiftUI
import WebKit

struct EmbeddedLegalDocumentView: View {
    let type: LegalDocumentType
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    private var title: String {
        switch type {
        case .privacy:
            return L10n.string(.privacyPolicy)
        case .terms:
            return L10n.string(.termsOfService)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                EmbeddedHTMLWebView(
                    html: LegalDocumentContent.html(for: type),
                    isLoading: $isLoading
                )
                .opacity(isLoading ? 0.02 : 1)

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.1)
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string(.close)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmbeddedHTMLWebView: UIViewRepresentable {
    let html: String
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.backgroundColor = .systemBackground
        webView.isOpaque = false
        context.coordinator.lastLoadedHTML = html
        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastLoadedHTML != html {
            context.coordinator.lastLoadedHTML = html
            isLoading = true
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var lastLoadedHTML: String = ""

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}
