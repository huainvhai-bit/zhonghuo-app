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
    @State private var showingTemplatePicker = false
    
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
                    // 使用模板按钮
                    Button(action: { showingTemplatePicker = true }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("使用模板")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
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
            .confirmationDialog("选择模板", isPresented: $showingTemplatePicker) {
                ForEach(getTemplatesForModule(module), id: \.title) { template in
                    Button(template.title) {
                        content = template.content
                    }
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
    
    private func getTemplatesForModule(_ module: WillModule) -> [(title: String, content: String)] {
        switch module.type {
        case .property:
            return [
                ("标准财产分配", """
                    本人 [姓名]，身份证号 [号码]，现将名下财产做如下分配：
                    
                    一、房产
                    位于 [地址] 的房产（房产证号：[号码]），由 [继承人姓名] 继承，占 100% 份额。
                    
                    二、银行存款
                    名下所有银行账户存款，由 [继承人姓名] 继承。
                    
                    三、其他财产
                    包括但不限于股票、基金、保险、车辆等，均由 [继承人姓名] 继承。
                    
                    四、遗嘱执行人
                    指定 [姓名] 为本遗嘱的执行人。
                    """),
                ("按比例分配", """
                    本人 [姓名]，身份证号 [号码]，现将名下财产做如下分配：
                    
                    一、房产
                    位于 [地址] 的房产，由 [继承人 A] 继承 [50]% 份额，[继承人 B] 继承 [50]% 份额。
                    
                    二、银行存款
                    名下所有银行存款，按以下比例分配：
                    - [继承人 A]：[50]%
                    - [继承人 B]：[50]%
                    
                    三、遗嘱执行人
                    指定 [姓名] 为本遗嘱的执行人。
                    """)
            ]
        case .heirs:
            return [
                ("继承人指定", """
                    本人 [姓名]，身份证号 [号码]，现将继承人指定如下：
                    
                    一、第一顺序继承人
                    配偶：[姓名]，身份证号：[号码]
                    子女：[姓名]，身份证号：[号码]
                    父母：[姓名]，身份证号：[号码]
                    
                    二、继承份额
                    上述继承人平均分配本人全部遗产。
                    
                    三、遗嘱执行人
                    指定 [姓名] 为本遗嘱的执行人。
                    """)
            ]
        case .specialItems:
            return [
                ("特殊物品分配", """
                    本人 [姓名]，身份证号 [号码]，现将特殊物品分配如下：
                    
                    一、首饰
                    [物品描述] 由 [姓名] 继承。
                    
                    二、收藏品
                    [物品描述] 由 [姓名] 继承。
                    
                    三、纪念品
                    [物品描述] 由 [姓名] 继承。
                    """)
            ]
        case .funeral:
            return [
                ("简约葬礼", """
                    本人 [姓名]，身份证号 [号码]，现将后事安排如下：
                    
                    一、葬礼形式
                    希望举行简约的告别仪式，不铺张浪费。
                    
                    二、骨灰处理
                    骨灰 [撒海/树葬/存放]，不留墓碑。
                    
                    三、其他要求
                    不举行追悼会，不通知亲友。
                    """),
                ("传统葬礼", """
                    本人 [姓名]，身份证号 [号码]，现将后事安排如下：
                    
                    一、葬礼形式
                    希望举行传统的告别仪式，地点在 [殡仪馆名称]。
                    
                    二、骨灰处理
                    骨灰安葬于 [墓地名称]，墓碑刻字：[碑文]。
                    
                    三、追悼会
                    希望举行追悼会，邀请亲友参加。
                    """)
            ]
        case .otherInstructions:
            return [
                ("其他嘱托", """
                    本人 [姓名]，身份证号 [号码]，现将其他嘱托如下：
                    
                    [请在此处填写您的嘱托内容]
                    """)
            ]
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

// MARK: - 添加/编辑资产弹窗
struct AddAssetModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    var asset: Asset? // nil 表示新增，非 nil 表示编辑
    
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
                        TextField("开户行", text: Binding(
                            get: { details["开户行"] ?? "" },
                            set: { details["开户行"] = $0 }
                        ))
                    case .stock:
                        TextField("持仓", text: Binding(
                            get: { details["持仓"] ?? "" },
                            set: { details["持仓"] = $0 }
                        ))
                    case .insurance:
                        TextField("保单号", text: Binding(
                            get: { details["保单号"] ?? "" },
                            set: { details["保单号"] = $0 }
                        ))
                        TextField("受益人", text: Binding(
                            get: { details["受益人"] ?? "" },
                            set: { details["受益人"] = $0 }
                        ))
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle(asset == nil ? "添加资产" : "编辑资产")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(asset == nil ? "添加" : "保存") {
                        if let existingAsset = asset {
                            // 编辑模式：更新现有资产
                            var updatedAsset = existingAsset
                            updatedAsset.type = selectedType
                            updatedAsset.name = name
                            updatedAsset.institution = institution
                            updatedAsset.balance = balance
                            updatedAsset.accountNumber = accountNumber
                            updatedAsset.details = details
                            dataManager.updateAsset(updatedAsset)
                        } else {
                            // 新增模式：创建新资产
                            let newAsset = Asset(
                                id: UUID().uuidString,
                                type: selectedType,
                                name: name,
                                institution: institution,
                                balance: balance,
                                accountNumber: accountNumber,
                                details: details,
                                createdAt: Date()
                            )
                            dataManager.addAsset(newAsset)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || institution.isEmpty)
                }
            }
            .onAppear {
                // 如果是编辑模式，加载现有数据
                if let existingAsset = asset {
                    selectedType = existingAsset.type
                    name = existingAsset.name
                    institution = existingAsset.institution
                    balanceText = String(format: "%.2f", existingAsset.balance)
                    accountNumber = existingAsset.accountNumber
                    details = existingAsset.details
                }
            }
        }
    }
}
