//
//  NavigationBarModifier.swift
//  终活
//
//  导航栏颜色扩展
//

import SwiftUI

// MARK: - 导航栏颜色扩展
struct NavigationBarColor: UIViewControllerRepresentable {
    let backgroundColor: UIColor
    let titleColor: UIColor
    
    func makeUIViewController(context: Context) -> UINavigationBarAppearanceController {
        return UINavigationBarAppearanceController()
    }
    
    func updateUIViewController(_ uiViewController: UINavigationBarAppearanceController, context: Context) {
        uiViewController.backgroundColor = backgroundColor
        uiViewController.titleColor = titleColor
    }
}

class UINavigationBarAppearanceController: UIViewController {
    var backgroundColor: UIColor = .clear
    var titleColor: UIColor = .label
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateNavigationBar()
    }
    
    private func updateNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
}

extension View {
    func navigationBarColor(background: Color, titleColor: Color) -> some View {
        self.background(
            NavigationBarColor(
                backgroundColor: UIColor(background),
                titleColor: UIColor(titleColor)
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        )
    }
}
