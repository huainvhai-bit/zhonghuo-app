//
//  WillModuleEdit.swift
//  终活
//
//  遗嘱模块编辑 + 模板
//

import SwiftUI

// MARK: - 编辑遗嘱模块弹窗
struct EditWillModuleModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    let module: WillModule
    @State private var content: String
    @State private var isCompleted: Bool
    
    init(dataManager: DataManager, module: WillModule) {
        self.dataManager = dataManager
        self.module = module
        _content = State(initialValue: module.content)
        _isCompleted = State(initialValue: module.isCompleted)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(module.title)) {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Toggle("标记为已完成", isOn: $isCompleted)
                }
            }
            .navigationTitle(module.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        var updated = module
                        updated.content = content
                        updated.isCompleted = isCompleted
                        dataManager.updateWillModule(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 模板弹窗
struct TemplateModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let templates: [(title: String, content: String)] = [
        (
            title: "标准财产分配",
            content: """
            本人 [姓名]，身份证号 [号码]，现将名下财产做如下分配：
            
            一、房产
            位于 [地址] 的房产（房产证号：[号码]），由 [继承人姓名] 继承，占 100% 份额。
            
            二、银行存款
            名下所有银行账户存款，由 [继承人姓名] 继承。
            
            三、其他财产
            包括但不限于股票、基金、保险、车辆等，均由 [继承人姓名] 继承。
            
            四、遗嘱执行人
            指定 [姓名] 为本遗嘱的执行人。
            
            立遗嘱人：[签名]
            日期：[年] 年 [月] 月 [日] 日
            """
        ),
        (
            title: "简单遗嘱",
            content: """
            本人 [姓名]，身份证号 [号码]，神志清醒，具有完全民事行为能力。
            
            现将本人名下全部财产（包括但不限于房产、存款、股票、基金、保险等）留给 [继承人姓名]（身份证号：[号码]）个人所有，不属于其夫妻共同财产。
            
            本遗嘱为本人真实意思表示，如有其他遗嘱与本遗嘱冲突，以本遗嘱为准。
            
            立遗嘱人：[签名]
            日期：[年] 年 [月] 月 [日] 日
            """
        ),
        (
            title: "丧葬意愿",
            content: """
            关于本人的丧葬事宜，希望家人遵循以下意愿：
            
            一、丧事从简
            不举行大型追悼会，仅邀请至亲好友参加告别仪式。
            
            二、火化
            遗体火化后，骨灰 [撒入大海/安葬于 XX 墓园/其他]。
            
            三、费用
            丧葬费用从本人名下存款中支出。
            
            四、其他
            [其他具体要求]
            
            立遗嘱人：[签名]
            日期：[年] 年 [月] 月 [日] 日
            """
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.title) { template in
                    Button(action: {
                        // TODO: 应用模板到对应模块
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.title)
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text(template.content.prefix(100))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("选择模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 添加资产弹窗
struct AddAssetModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: Asset.AssetType = .bank
    @State private var name = ""
    @State private var institution = ""
    @State private var balanceText = ""
    @State private var accountNumber = ""
    @State private var details: [String: String] = [:]
    
    var balance: Double {
        Double(balanceText.replacingOccurrences(of: ",", with: "")) ?? 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("资产类型")) {
                    Picker("类型", selection: $selectedType) {
                        ForEach(Asset.AssetType.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.rawValue)").tag(type)
                        }
                    }
                }
                
                Section(header: Text("基本信息")) {
                    TextField("资产名称（如：工商银行储蓄卡）", text: $name)
                    
                    TextField("机构名称（如：中国工商银行）", text: $institution)
                    
                    TextField("余额（元）", text: $balanceText)
                        .keyboardType(.decimalPad)
                    
                    TextField("账号后 4 位", text: $accountNumber)
                }
                
                Section(header: Text("详细信息")) {
                    switch selectedType {
                    case .bank:
                        TextField("开户行", text: $details["开户行", default: ""])
                    case .stock:
                        TextField("持仓", text: $details["持仓", default: ""])
                    case .insurance:
                        TextField("保单号", text: $details["保单号", default: ""])
                        TextField("受益人", text: $details["受益人", default: ""])
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("添加资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        dataManager.addAsset(
                            type: selectedType,
                            name: name,
                            institution: institution,
                            balance: balance,
                            accountNumber: accountNumber,
                            details: details
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || institution.isEmpty)
                }
            }
        }
    }
}
