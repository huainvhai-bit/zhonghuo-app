//
//  WillAssetsView.swift
//  终活 - 遗嘱与资产
//

import SwiftUI

struct WillAssetsView: View {
    @State private var selectedSection = 0
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("遗嘱")) {
                    NavigationLink(destination: WillListView()) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.warningOrange)
                            Text("我的遗嘱")
                            Spacer()
                            Text("未设置")
                                .foregroundColor(.textSecondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Section(header: Text("资产")) {
                    NavigationLink(destination: AssetListView()) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.accentGreen)
                            Text("资产清单")
                            Spacer()
                            Text("0 项")
                                .foregroundColor(.textSecondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    NavigationLink(destination: AccountListView()) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.primaryPurple)
                            Text("账户信息")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("嘱托与资产")
        }
    }
}

struct WillListView: View {
    var body: some View {
        Text("遗嘱列表")
            .navigationTitle("我的遗嘱")
    }
}

struct AssetListView: View {
    var body: some View {
        Text("资产列表")
            .navigationTitle("资产清单")
    }
}

struct AccountListView: View {
    var body: some View {
        Text("账户列表")
            .navigationTitle("账户信息")
    }
}

#Preview {
    WillAssetsView()
}
