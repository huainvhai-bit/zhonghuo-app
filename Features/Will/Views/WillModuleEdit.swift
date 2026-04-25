//
//  WillModuleEdit.swift
//  终活
//
//  遗嘱模块编辑 + 模板
//

import SwiftUI

// MARK: - 模板缓存（避免每次打开对话框都重新创建大字符串）
private struct CachedTemplates {
    static var propertyTemplates: [(title: String, content: String)] { [
        (
            L10n.text("标准财产分配", en: "Standard Asset Distribution", ja: "標準財産分配", ko: "표준 재산 분배"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将名下财产做如下分配：
            
            一、房产
            位于 [地址] 的房产（房产证号：[号码]），由 [继承人姓名] 继承，占 100% 份额。
            
            二、银行存款
            名下所有银行账户存款，由 [继承人姓名] 继承。
            
            三、其他财产
            包括但不限于股票、基金、保险、车辆等，均由 [继承人姓名] 继承。
            
            四、遗嘱执行人
            指定 [姓名] 为本遗嘱的执行人。
            """, en: """
            I, [Name], ID No. [Number], distribute my assets as follows:

            1. Real estate
            The property at [Address] (Property No. [Number]) shall be inherited by [Heir Name] in full.

            2. Bank deposits
            All bank account deposits shall be inherited by [Heir Name].

            3. Other assets
            Including but not limited to stocks, funds, insurance, and vehicles, shall be inherited by [Heir Name].

            4. Executor
            Appoint [Name] as the executor of this will.
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、以下のとおり財産を分配します。

            1. 不動産
            [住所] の不動産（登記番号：[番号]）は [相続人名] に相続させます。

            2. 預金
            すべての銀行預金を [相続人名] に相続させます。

            3. その他の資産
            株式、投資信託、保険、車両などを含むその他資産を [相続人名] に相続させます。

            4. 遺言執行者
            [氏名] を本遺言の執行者に指定します。
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래와 같이 재산을 분배합니다.

            1. 부동산
            [주소]의 부동산(등기번호: [번호])은 [상속인]이 전부 상속합니다.

            2. 예금
            모든 은행 계좌 예금은 [상속인]이 상속합니다.

            3. 기타 재산
            주식, 펀드, 보험, 차량 등을 포함한 기타 재산은 [상속인]이 상속합니다.

            4. 유언 집행자
            [이름]을 이 유언의 집행자로 지정합니다.
            """)
        ),
        (
            L10n.text("按比例分配", en: "Proportional Distribution", ja: "割合分配", ko: "비율 분배"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将名下财产做如下分配：
            
            一、房产
            位于 [地址] 的房产，由 [继承人 A] 继承 [50]% 份额，[继承人 B] 继承 [50]% 份额。
            
            二、银行存款
            名下所有银行存款，按以下比例分配：
            - [继承人 A]：[50]%
            - [继承人 B]：[50]%
            
            三、遗嘱执行人
            指定 [姓名] 为本遗嘱的执行人。
            """, en: """
            I, [Name], ID No. [Number], distribute my assets as follows:

            1. Real estate
            The property at [Address] shall be inherited 50% by [Heir A] and 50% by [Heir B].

            2. Bank deposits
            All bank deposits shall be distributed as follows:
            - [Heir A]: 50%
            - [Heir B]: 50%

            3. Executor
            Appoint [Name] as the executor of this will.
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、以下のとおり財産を分配します。

            1. 不動産
            [住所] の不動産は、[相続人A] に50%、[相続人B] に50% 相続させます。

            2. 預金
            すべての銀行預金を以下の割合で分配します。
            - [相続人A]：50%
            - [相続人B]：50%

            3. 遺言執行者
            [氏名] を本遺言の執行者に指定します。
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래와 같이 재산을 분배합니다.

            1. 부동산
            [주소]의 부동산은 [상속인 A]에게 50%, [상속인 B]에게 50% 상속합니다.

            2. 예금
            모든 은행 예금은 아래와 같이 분배합니다.
            - [상속인 A]: 50%
            - [상속인 B]: 50%

            3. 유언 집행자
            [이름]을 이 유언의 집행자로 지정합니다.
            """)
        )
    ] }
    
    static var heirsTemplates: [(title: String, content: String)] { [
        (
            L10n.text("继承人指定", en: "Heir Designation", ja: "相続人指定", ko: "상속인 지정"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将继承人指定如下：
            
            一、第一顺序继承人
            配偶：[姓名]，身份证号：[号码]
            子女：[姓名]，身份证号：[号码]
            父母：[姓名]，身份证号：[号码]
            
            二、继承份额
            上述继承人平均分配本人全部遗产。
            
            三、遗嘱执行人
            指定 [姓名] 为本遗嘱的执行人。
            """, en: """
            I, [Name], ID No. [Number], designate the following heirs:

            1. First-order heirs
            Spouse: [Name], ID No. [Number]
            Children: [Name], ID No. [Number]
            Parents: [Name], ID No. [Number]

            2. Inheritance share
            The above heirs shall share all of my estate equally.

            3. Executor
            Appoint [Name] as the executor of this will.
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、以下の相続人を指定します。

            1. 第1順位相続人
            配偶者：[氏名]、身分証番号：[番号]
            子：[氏名]、身分証番号：[番号]
            父母：[氏名]、身分証番号：[番号]

            2. 相続割合
            上記相続人で遺産を均等に分配します。

            3. 遺言執行者
            [氏名] を本遺言の執行者に指定します。
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래 상속인을 지정합니다.

            1. 1순위 상속인
            배우자: [이름], 주민등록번호 [번호]
            자녀: [이름], 주민등록번호 [번호]
            부모: [이름], 주민등록번호 [번호]

            2. 상속 비율
            위 상속인들이 모든 유산을 균등 분배합니다.

            3. 유언 집행자
            [이름]을 이 유언의 집행자로 지정합니다.
            """)
        )
    ] }
    
    static var specialItemsTemplates: [(title: String, content: String)] { [
        (
            L10n.text("特殊物品分配", en: "Special Item Distribution", ja: "特別品の分配", ko: "특별 물품 분배"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将特殊物品分配如下：
            
            一、首饰
            [物品描述] 由 [姓名] 继承。
            
            二、收藏品
            [物品描述] 由 [姓名] 继承。
            
            三、纪念品
            [物品描述] 由 [姓名] 继承。
            """, en: """
            I, [Name], ID No. [Number], distribute special items as follows:

            1. Jewelry
            [Item description] shall be inherited by [Name].

            2. Collectibles
            [Item description] shall be inherited by [Name].

            3. Memorabilia
            [Item description] shall be inherited by [Name].
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、以下の特別品を分配します。

            1. 宝飾品
            [品目の説明] は [氏名] に相続させます。

            2. コレクション
            [品目の説明] は [氏名] に相続させます。

            3. 記念品
            [品目の説明] は [氏名] に相続させます。
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래 특별 물품을 분배합니다.

            1. 장신구
            [물품 설명]은 [이름]이 상속합니다.

            2. 수집품
            [물품 설명]은 [이름]이 상속합니다.

            3. 기념품
            [물품 설명]은 [이름]이 상속합니다.
            """)
        )
    ] }
    
    static var funeralTemplates: [(title: String, content: String)] { [
        (
            L10n.text("简约葬礼", en: "Simple Funeral", ja: "簡素な葬儀", ko: "간소한 장례"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将后事安排如下：
            
            一、葬礼形式
            希望举行简约的告别仪式，不铺张浪费。
            
            二、骨灰处理
            骨灰 [撒海/树葬/存放]，不留墓碑。
            
            三、其他要求
            不举行追悼会，不通知亲友。
            """, en: """
            I, [Name], ID No. [Number], arrange the following funeral wishes:

            1. Ceremony
            I prefer a simple farewell ceremony without extravagance.

            2. Ash handling
            Ashes should be [scattered at sea / tree buried / stored], with no tombstone.

            3. Other wishes
            No memorial service and no notification to friends or relatives.
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、以下の葬儀の希望を残します。

            1. 葬儀形式
            簡素なお別れの儀式を希望し、華美にしないでください。

            2. 遺灰の扱い
            遺灰は [海洋散骨 / 樹木葬 / 保管] とし、墓石は設けません。

            3. その他
            追悼式は行わず、親族や友人への連絡も不要です。
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래와 같은 장례 희망을 남깁니다.

            1. 장례 방식
            화려하지 않은 간소한 고별식을 원합니다.

            2. 유골 처리
            유골은 [바다에 뿌림 / 수목장 / 보관]하며 묘비는 두지 않습니다.

            3. 기타 요청
            추모식은 진행하지 않으며 친지에게 알리지 않습니다.
            """)
        ),
        (
            L10n.text("传统葬礼", en: "Traditional Funeral", ja: "伝統的な葬儀", ko: "전통 장례"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将后事安排如下：
            
            一、葬礼形式
            希望举行传统的告别仪式，地点在 [殡仪馆名称]。
            
            二、骨灰处理
            骨灰安葬于 [墓园名称]。
            
            三、丧葬费用
            丧葬费用预计 [金额] 元。
            """, en: """
            I, [Name], ID No. [Number], arrange the following funeral wishes:

            1. Ceremony
            I prefer a traditional farewell ceremony at [Funeral Home Name].

            2. Ash handling
            Ashes should be interred at [Cemetery Name].

            3. Funeral expenses
            Estimated funeral cost: [Amount].
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、以下の葬儀の希望を残します。

            1. 葬儀形式
            [斎場名] にて伝統的なお別れの儀式を希望します。

            2. 遺灰の扱い
            遺灰は [墓園名] に埋葬してください。

            3. 葬儀費用
            葬儀費用の見積もりは [金額] 元です。
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래와 같은 장례 희망을 남깁니다.

            1. 장례 방식
            [장례식장명]에서 전통적인 고별식을 원합니다.

            2. 유골 처리
            유골은 [묘지명]에 안장해 주세요.

            3. 장례 비용
            예상 장례 비용은 [금액] 위안입니다.
            """)
        )
    ] }
    
    static var otherInstructionsTemplates: [(title: String, content: String)] { [
        (
            L10n.text("其他嘱托", en: "Other Instructions", ja: "その他の遺言", ko: "기타 유언"),
            L10n.text("""
            本人 [姓名]，身份证号 [号码]，现将其他嘱托如下：
            
            [请在此处填写您的嘱托内容]
            """, en: """
            I, [Name], ID No. [Number], leave the following instructions:

            [Please fill in your instructions here]
            """, ja: """
            私、[氏名]、身分証番号 [番号] は、その他の遺言を以下のとおり残します。

            [ここにご希望を入力してください]
            """, ko: """
            본인 [이름], 주민등록번호 [번호]는 아래와 같은 기타 유언을 남깁니다.

            [여기에 내용을 입력하세요]
            """)
        )
    ] }
}

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
            return L10n.text("财产分配", en: "Asset Distribution", ja: "財産分配", ko: "재산 분배")
        case .heirs:
            return L10n.text("继承人指定", en: "Heir Designation", ja: "相続人指定", ko: "상속인 지정")
        case .specialItems:
            return L10n.text("特殊物品", en: "Special Items", ja: "特別品", ko: "특별 물품")
        case .funeral:
            return L10n.text("丧葬意愿", en: "Funeral Wishes", ja: "葬儀の希望", ko: "장례 희망")
        case .otherInstructions:
            return L10n.text("其他嘱托", en: "Other Instructions", ja: "その他の遺言", ko: "기타 유언")
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
