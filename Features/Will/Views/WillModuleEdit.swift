//
//  WillModuleEdit.swift
//  安心助手
//
//  重要事项编辑 + 模板
//

import SwiftUI

// MARK: - 模板缓存（避免每次打开对话框都重新创建大字符串）
private struct CachedTemplates {
    static var propertyTemplates: [(title: String, content: String)] { [
        (
            L10n.text("资产记录模板", en: "Asset Notes Template", ja: "資産メモテンプレート", ko: "자산 기록 템플릿"),
            L10n.text("""
            本人 [姓名]，现记录名下资产信息如下，供个人整理和信息参考：
            
            一、房产
            位于 [地址] 的房产（房产证号：[号码]），备注：[填写说明]。
            
            二、银行存款
            银行账户信息：[填写银行、账号后四位、备注]。
            
            三、其他资产
            包括但不限于股票、基金、保险、车辆等：[填写说明]。
            
            四、联系人
            如需添加用户协助核对，可联系：[姓名/联系方式]。
            """, en: """
            I, [Name], record my asset information for personal organization and family communication:

            1. Real estate
            Property at [Address] (certificate no. [Number]), notes: [Notes].

            2. Bank deposits
            Bank account information: [Bank, last four digits, notes].

            3. Other assets
            Stocks, funds, insurance, vehicles, etc.: [Notes].

            4. Contact
            For family reference, contact: [Name / Contact].
            """, ja: """
            私、[氏名] は、個人整理と共有参考として資産情報を記録します。

            1. 不動産
            [住所 / 登録番号 / メモ]

            2. 預金
            [銀行名 / 口座下4桁 / メモ]

            3. その他の資産
            [株式、投資信託、保険、車両などのメモ]

            4. 連絡先
            相手が確認する際の連絡先：[氏名 / 連絡先]
            """, ko: """
            본인 [이름]은 개인 정리와 가족 공유 참고용으로 자산 정보를 기록합니다.

            1. 부동산
            [주소 / 등기번호 / 메모]

            2. 예금
            [은행명 / 계좌 끝 4자리 / 메모]

            3. 기타 자산
            [주식, 펀드, 보험, 차량 등 메모]

            4. 연락처
            가족이 확인할 때 참고할 연락처: [이름 / 연락처]
            """)
        ),
        (
            L10n.text("资产备注模板", en: "Asset Notes", ja: "資産メモ", ko: "자산 메모"),
            L10n.text("""
            本人 [姓名]，现将名下资产按类别整理如下：
            
            一、房产
            [地址/证号/备注]
            
            二、银行存款
            [银行名称/账号后四位/备注]
            
            三、投资与保险
            [平台或机构/账号后四位/备注]
            """, en: """
            I, [Name], organize my assets by category:

            1. Real estate
            [Address / certificate no. / notes]

            2. Bank deposits
            [Bank / last four digits / notes]

            3. Investments and insurance
            [Platform or institution / last four digits / notes]
            """, ja: """
            私、[氏名] は、資産をカテゴリ別に整理します。

            1. 不動産
            [住所 / 登録番号 / メモ]

            2. 預金
            [銀行名 / 口座下4桁 / メモ]

            3. 投資と保険
            [サービス名または機関 / メモ]
            """, ko: """
            본인 [이름]은 자산을 종류별로 정리합니다.

            1. 부동산
            [주소 / 등기번호 / 메모]

            2. 예금
            [은행명 / 계좌 끝 4자리 / 메모]

            3. 투자와 보험
            [서비스 또는 기관 / 메모]
            """)
        )
    ] }
    
    static var heirsTemplates: [(title: String, content: String)] { [
        (
            L10n.text("添加用户记录", en: "Added Contacts", ja: "追加連絡先", ko: "추가 연락처"),
            L10n.text("""
            本人 [姓名]，现记录添加用户和重要联系人信息如下：
            
            一、添加用户
            配偶：[姓名]，身份证号：[号码]
            子女：[姓名]，身份证号：[号码]
            父母：[姓名]，身份证号：[号码]
            
            二、联系方式
            电话/地址/其他备注：[填写说明]
            
            三、备注
            [填写希望添加用户了解的事项]
            """, en: """
            I, [Name], record family members and important contacts:

            1. Family members
            Spouse: [Name], ID No. [Number]
            Children: [Name], ID No. [Number]
            Parents: [Name], ID No. [Number]

            2. Contact info
            Phone / address / notes: [Notes]

            3. Communication notes
            [Notes for family]
            """, ja: """
            私、[氏名] は、共有相手と重要な連絡先を記録します。

            1. 添加用户
            配偶者：[氏名 / 連絡先]
            子：[氏名 / 連絡先]
            父母：[氏名 / 連絡先]

            2. 連絡方法
            電話 / 住所 / その他メモ：[メモ]

            3. 添加备注
            [共有相手に伝えたい内容]
            """, ko: """
            본인 [이름]은 가족과 중요한 연락처를 기록합니다.

            1. 가족
            배우자: [이름 / 연락처]
            자녀: [이름 / 연락처]
            부모: [이름 / 연락처]

            2. 연락 방법
            전화 / 주소 / 기타 메모: [메모]

            3. 가족 공유 메모
            [가족에게 남기고 싶은 내용]
            """)
        )
    ] }
    
    static var specialItemsTemplates: [(title: String, content: String)] { [
        (
            L10n.text("特殊物品记录", en: "Special Item Notes", ja: "特別品メモ", ko: "특별 물품 기록"),
            L10n.text("""
            本人 [姓名]，现记录特殊物品信息如下：
            
            一、首饰
            [物品描述/存放位置/备注]
            
            二、收藏品
            [物品描述/存放位置/备注]
            
            三、纪念品
            [物品描述/存放位置/备注]
            """, en: """
            I, [Name], record special item information:

            1. Jewelry
            [Description / storage location / notes]

            2. Collectibles
            [Description / storage location / notes]

            3. Memorabilia
            [Description / storage location / notes]
            """, ja: """
            私、[氏名] は、特別な品物を記録します。

            1. 宝飾品
            [説明 / 保管場所 / メモ]

            2. コレクション
            [説明 / 保管場所 / メモ]

            3. 記念品
            [説明 / 保管場所 / メモ]
            """, ko: """
            본인 [이름]은 특별 물품 정보를 기록합니다.

            1. 장신구
            [설명 / 보관 위치 / 메모]

            2. 수집품
            [설명 / 보관 위치 / 메모]

            3. 기념품
            [설명 / 보관 위치 / 메모]
            """)
        )
    ] }
    
    static var funeralTemplates: [(title: String, content: String)] { [
        (
            L10n.text("个人偏好记录", en: "Personal Preferences", ja: "個人設定メモ", ko: "개인 선호 기록"),
            L10n.text("""
            本人 [姓名]，现记录个人偏好如下，供信息参考：
            
            一、生活偏好
            [请填写您希望添加用户了解的生活习惯或偏好]
            
            二、备注说明
            [请填写希望添加用户查看时注意的事项]
            
            三、其他备注
            [其他想记录的内容]
            """, en: """
            I, [Name], record personal preferences for family communication:

            1. Daily preferences
            [Habits or preferences for family reference]

            2. Family communication
            [Notes for family communication]

            3. Other notes
            [Other content]
            """, ja: """
            私、[氏名] は、共有参考として個人設定を記録します。

            1. 生活上の好み
            [共有相手に知ってほしい習慣や好み]

            2. 共有相手とのコミュニケーション
            [共有相手とのやり取りで大切にしたいこと]

            3. その他メモ
            [その他の内容]
            """, ko: """
            본인 [이름]은 가족 공유 참고용으로 개인 선호를 기록합니다.

            1. 생활 선호
            [가족이 알아두면 좋은 습관이나 선호]

            2. 가족 소통
            [가족과 소통할 때 참고할 내용]

            3. 기타 메모
            [기타 내용]
            """)
        ),
        (
            L10n.text("备注说明", en: "Notes", ja: "メモ", ko: "메모"),
            L10n.text("""
            本人 [姓名]，现记录希望添加用户了解的事项：
            
            一、重要联系人
            [姓名/联系方式/关系]
            
            二、亲友事项
            [需要添加用户了解或协助的事项]
            
            三、其他备注
            [其他说明]
            """, en: """
            I, [Name], record notes for family:

            1. Important contacts
            [Name / contact / relationship]

            2. Family matters
            [Matters family should know or help with]

            3. Other notes
            [Other notes]
            """, ja: """
            私、[氏名] は、共有相手に伝えたい内容を記録します。

            1. 重要な連絡先
            [氏名 / 連絡先 / 関係]

            2. 共有事項
            [共有相手に知ってほしい、または協力してほしい内容]

            3. その他メモ
            [その他]
            """, ko: """
            본인 [이름]은 가족에게 공유하고 싶은 내용을 기록합니다.

            1. 중요한 연락처
            [이름 / 연락처 / 관계]

            2. 가족 관련 사항
            [가족이 알아야 하거나 도와주면 좋은 내용]

            3. 기타 메모
            [기타]
            """)
        )
    ] }
    
    static var otherInstructionsTemplates: [(title: String, content: String)] { [
        (
            L10n.text("其他事项", en: "Other Notes", ja: "その他メモ", ko: "기타 메모"),
            L10n.text("""
            本人 [姓名]，现记录其他事项如下：
            
            [请在此处填写您想记录的内容]
            """, en: """
            I, [Name], record the following notes:

            [Please fill in your notes here]
            """, ja: """
            私、[氏名] は、その他の内容を記録します。

            [ここに内容を入力してください]
            """, ko: """
            본인 [이름]은 기타 내용을 기록합니다.

            [여기에 내용을 입력하세요]
            """)
        )
    ] }
}

// MARK: - 编辑重要事项弹窗
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
                Section(header: Text(localizedModuleTitle(module.type))) {
                    // 使用模板按钮
                    Button(action: { showingTemplatePicker = true }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text(L10n.text("使用模板", en: "Use Template", ja: "テンプレートを使用", ko: "템플릿 사용"))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Toggle(L10n.text("标记为已完成", en: "Mark as Completed", ja: "完了にする", ko: "완료로 표시"), isOn: $isCompleted)
                }
            }
            .navigationTitle(localizedModuleTitle(module.type))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.save)) {
                        saveModule()
                    }
                }
            }
            .confirmationDialog(L10n.text("选择模板", en: "Choose Template", ja: "テンプレートを選択", ko: "템플릿 선택"), isPresented: $showingTemplatePicker) {
                ForEach(getTemplatesForModule(module), id: \.title) { template in
                    Button(template.title) {
                        self.content = template.content
                        // ✅ 填写内容后自动标记为完成
                        self.isCompleted = !self.content.isEmpty
                    }
                }
                Button(L10n.string(.cancel), role: .cancel) {}
            }
        }
        .stackNavigationStyle()
    }
    
    // ✅ 保存时根据内容自动判断是否完成
    private func saveModule() {
        var updated = module
        updated.content = content
        // 内容不为空时自动标记为完成
        updated.isCompleted = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        dataManager.updateWillModule(updated)
        dismiss()
    }
    
    private func getTemplatesForModule(_ module: WillModule) -> [(title: String, content: String)] {
        // ✅ 使用缓存的模板，避免每次打开对话框都重新创建大字符串
        switch module.type {
        case .property:
            return CachedTemplates.propertyTemplates
        case .heirs:
            return CachedTemplates.heirsTemplates
        case .specialItems:
            return CachedTemplates.specialItemsTemplates
        case .funeral:
            return CachedTemplates.funeralTemplates
        case .otherInstructions:
            return CachedTemplates.otherInstructionsTemplates
        }
    }

    private func localizedModuleTitle(_ type: WillModule.WillType) -> String {
        switch type {
        case .property:
            return L10n.text("资产记录", en: "Asset Notes", ja: "資産メモ", ko: "자산 기록")
        case .heirs:
            return L10n.text("添加用户", en: "Added Contacts", ja: "追加連絡先", ko: "추가 연락처")
        case .specialItems:
            return L10n.text("特殊物品", en: "Special Items", ja: "特別品", ko: "특별 물품")
        case .funeral:
            return L10n.text("个人偏好", en: "Personal Preferences", ja: "個人設定", ko: "개인 선호")
        case .otherInstructions:
            return L10n.text("其他事项", en: "Other Notes", ja: "その他メモ", ko: "기타 메모")
        }
    }
}

// MARK: - 模板弹窗
struct TemplateModal: View {
    @ObservedObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    @Binding var content: String
    @Binding var isCompleted: Bool
    
    let templates: [(title: String, content: String)] = [
        (
            title: "资产记录模板",
            content: """
            本人 [姓名]，现将名下资产信息整理如下：
            
            一、房产
            [地址/证号/备注]
            
            二、银行存款
            [银行名称/账号后四位/备注]
            
            三、其他资产
            [股票、基金、保险、车辆等备注]
            
            记录人：[签名]
            日期：[年] 年 [月] 月 [日] 日
            """
        ),
        (
            title: "备注说明",
            content: """
            本人 [姓名]，现记录希望添加用户了解的事项：
            
            一、重要联系人
            [姓名/联系方式/关系]
            
            二、添加事项
            [需要添加用户了解或协助的事项]
            
            记录人：[签名]
            日期：[年] 年 [月] 月 [日] 日
            """
        ),
        (
            title: "个人偏好",
            content: """
            本人 [姓名]，现记录个人偏好如下，供信息参考：
            
            一、生活偏好
            [请填写您希望添加用户了解的生活习惯或偏好]
            
            二、备注说明
            [请填写希望添加用户查看时注意的事项]
            
            三、其他
            [其他具体要求]
            
            记录人：[签名]
            日期：[年] 年 [月] 月 [日] 日
            """
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.title) { template in
                    Button(action: {
                        // ✅ 应用模板到对应模块
                        content = template.content
                        isCompleted = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            .navigationTitle(L10n.text("选择模板", en: "Choose Template", ja: "テンプレートを選択", ko: "템플릿 선택"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
            }
        }
        .stackNavigationStyle()
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
                Section(header: Text(L10n.text("资产类型", en: "Asset Type", ja: "資産種類", ko: "자산 유형"))) {
                    Picker(L10n.text("类型", en: "Type", ja: "種類", ko: "유형"), selection: $selectedType) {
                        ForEach(Asset.AssetType.allCases, id: \.self) { type in
                            Text("\(type.icon) \(localizedAssetType(type))").tag(type)
                        }
                    }
                }
                
                Section(header: Text(L10n.text("基本信息", en: "Basic Info", ja: "基本情報", ko: "기본 정보"))) {
                    TextField(L10n.text("资产名称（如：工商银行储蓄卡）", en: "Asset name (e.g. ICBC debit card)", ja: "資産名（例：工商銀行の預金カード）", ko: "자산명(예: 공상은행 체크카드)"), text: $name)
                    
                    TextField(L10n.text("机构名称（如：中国工商银行）", en: "Institution (e.g. ICBC)", ja: "機関名（例：中国工商銀行）", ko: "기관명(예: 중국공상은행)"), text: $institution)
                    
                    TextField(L10n.text("余额（元）", en: "Balance (CNY)", ja: "残高（元）", ko: "잔액(위안)"), text: $balanceText)
                        .keyboardType(.decimalPad)
                    
                    TextField(L10n.text("账号后 4 位", en: "Last 4 digits of account", ja: "口座番号下4桁", ko: "계좌번호 끝 4자리"), text: $accountNumber)
                }
                
                Section(header: Text(L10n.text("详细信息", en: "Details", ja: "詳細情報", ko: "상세 정보"))) {
                    switch selectedType {
                    case .bank:
                        TextField(L10n.text("开户行", en: "Branch", ja: "支店", ko: "지점"), text: Binding(
                            get: { details["开户行"] ?? "" },
                            set: { details["开户行"] = $0 }
                        ))
                        TextField(L10n.text("账号后 4 位", en: "Last 4 digits of account", ja: "口座番号下4桁", ko: "계좌번호 끝 4자리"), text: Binding(
                            get: { details["bank_account"] ?? "" },
                            set: { details["bank_account"] = $0 }
                        ))
                    case .stock:
                        TextField(L10n.text("券商", en: "Broker", ja: "証券会社", ko: "증권사"), text: Binding(
                            get: { details["券商"] ?? "" },
                            set: { details["券商"] = $0 }
                        ))
                        TextField(L10n.text("资金账号", en: "Trading account", ja: "資金口座", ko: "자금 계좌"), text: Binding(
                            get: { details["资金账号"] ?? "" },
                            set: { details["资金账号"] = $0 }
                        ))
                    case .fund:
                        TextField(L10n.text("基金公司", en: "Fund company", ja: "ファンド会社", ko: "펀드 회사"), text: Binding(
                            get: { details["基金公司"] ?? "" },
                            set: { details["基金公司"] = $0 }
                        ))
                        TextField(L10n.text("基金代码", en: "Fund code", ja: "ファンドコード", ko: "펀드 코드"), text: Binding(
                            get: { details["基金代码"] ?? "" },
                            set: { details["基金代码"] = $0 }
                        ))
                    case .insurance:
                        TextField(L10n.text("保险公司", en: "Insurance company", ja: "保険会社", ko: "보험사"), text: Binding(
                            get: { details["保险公司"] ?? "" },
                            set: { details["保险公司"] = $0 }
                        ))
                        TextField(L10n.text("保单号", en: "Policy number", ja: "保険証券番号", ko: "보험증권 번호"), text: Binding(
                            get: { details["保单号"] ?? "" },
                            set: { details["保单号"] = $0 }
                        ))
                        TextField(L10n.text("受益人", en: "Beneficiary", ja: "受取人", ko: "수익자"), text: Binding(
                            get: { details["受益人"] ?? "" },
                            set: { details["受益人"] = $0 }
                        ))
                    case .cash:
                        TextField(L10n.text("存放位置", en: "Storage location", ja: "保管場所", ko: "보관 위치"), text: Binding(
                            get: { details["存放位置"] ?? "" },
                            set: { details["存放位置"] = $0 }
                        ))
                        TextField(L10n.text("备注", en: "Notes", ja: "備考", ko: "비고"), text: Binding(
                            get: { details["备注"] ?? "" },
                            set: { details["备注"] = $0 }
                        ))
                    case .property:
                        TextField(L10n.text("房产地址", en: "Property address", ja: "不動産の住所", ko: "부동산 주소"), text: Binding(
                            get: { details["地址"] ?? "" },
                            set: { details["地址"] = $0 }
                        ))
                        TextField(L10n.text("房产证号", en: "Property certificate No.", ja: "登記番号", ko: "등기번호"), text: Binding(
                            get: { details["房产证号"] ?? "" },
                            set: { details["房产证号"] = $0 }
                        ))
                        TextField(L10n.text("面积（㎡）", en: "Area (㎡)", ja: "面積（㎡）", ko: "면적(㎡)"), text: Binding(
                            get: { details["面积"] ?? "" },
                            set: { details["面积"] = $0 }
                        ))
                    case .gameAccount:
                        TextField(L10n.text("游戏名称", en: "Game name", ja: "ゲーム名", ko: "게임 이름"), text: Binding(
                            get: { details["游戏名称"] ?? "" },
                            set: { details["游戏名称"] = $0 }
                        ))
                        TextField(L10n.text("账号/ID", en: "Account/ID", ja: "アカウント/ID", ko: "계정/ID"), text: Binding(
                            get: { details["账号"] ?? "" },
                            set: { details["账号"] = $0 }
                        ))
                        TextField(L10n.text("服务器/区服", en: "Server/Region", ja: "サーバー/区", ko: "서버/구역"), text: Binding(
                            get: { details["服务器"] ?? "" },
                            set: { details["服务器"] = $0 }
                        ))
                    case .crypto:
                        TextField(L10n.text("币种", en: "Currency", ja: "通貨", ko: "통화"), text: Binding(
                            get: { details["币种"] ?? "" },
                            set: { details["币种"] = $0 }
                        ))
                        TextField(L10n.text("钱包地址", en: "Wallet address", ja: "ウォレットアドレス", ko: "지갑 주소"), text: Binding(
                            get: { details["钱包地址"] ?? "" },
                            set: { details["钱包地址"] = $0 }
                        ))
                        TextField(L10n.text("交易所", en: "Exchange", ja: "取引所", ko: "거래소"), text: Binding(
                            get: { details["交易所"] ?? "" },
                            set: { details["交易所"] = $0 }
                        ))
                    }
                }
            }
            .navigationTitle(asset == nil ? L10n.text("添加资产", en: "Add Asset", ja: "資産を追加", ko: "자산 추가") : L10n.text("编辑资产", en: "Edit Asset", ja: "資産を編集", ko: "자산 편집"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.string(.cancel)) { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(asset == nil ? L10n.text("添加", en: "Add", ja: "追加", ko: "추가") : L10n.string(.save)) {
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
        .stackNavigationStyle()
    }

    private func localizedAssetType(_ type: Asset.AssetType) -> String {
        switch type {
        case .bank: return L10n.text("银行", en: "Bank", ja: "銀行", ko: "은행")
        case .stock: return L10n.text("股票", en: "Stock", ja: "株式", ko: "주식")
        case .fund: return L10n.text("基金", en: "Fund", ja: "投資信託", ko: "펀드")
        case .insurance: return L10n.text("保险", en: "Insurance", ja: "保険", ko: "보험")
        case .cash: return L10n.text("现金", en: "Cash", ja: "現金", ko: "현금")
        case .property: return L10n.text("房产", en: "Property", ja: "不動産", ko: "부동산")
        case .gameAccount: return L10n.text("游戏账号", en: "Game Account", ja: "ゲームアカウント", ko: "게임 계정")
        case .crypto: return L10n.text("数字资产", en: "Crypto", ja: "暗号資産", ko: "암호자산")
        @unknown default: return type.rawValue
        }
    }
}
