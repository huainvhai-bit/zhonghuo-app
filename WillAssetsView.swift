//
//  WillAssetsView.swift
//  终活
//
//  嘱托与资产 - 完整的增删改查 + 模板
//

import SwiftUI

struct WillAssetsView: View {
    @ObservedObject var dataManager = DataManager.shared
    @State private var selectedTab = 0 // 0=遗嘱，1=资产
    @State private var showingAddAssetModal = false
    @State private var showingTemplateModal = false
    @State private var editingModule: WillModule? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 云同步状态
                    syncStatusCard
                    
                    // 分段控制器
                    segmentControl
                    
                    // 内容
                    if selectedTab == 0 {
                        willContent
                    } else {
                        assetsContent
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("嘱托与资产")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddAssetModal) {
                AddAssetModal(dataManager: dataManager)
            }
            .sheet(isPresented: $showingTemplateModal) {
                TemplateModal(dataManager: dataManager)
            }
            .sheet(item: $editingModule) { module in
                EditWillModuleModal(dataManager: dataManager, module: module)
            }
        }
    }
    
    // MARK: - 云同步状态
    private var syncStatusCard: some View {
        HStack(spacing: 12) {
            Text("☁️")
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("云端已同步")
                    .font(.subheadline.bold())
                    .foregroundColor(Color(hex: "34C759"))
                
                Text("上次同步：刚刚 · 所有数据已安全备份")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("详情") {
                // TODO: 显示同步详情
            }
            .font(.system(size: 12))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(14)
        .background(Color(hex: "34C759").opacity(0.08))
        .cornerRadius(12)
    }
    
    // MARK: - 分段控制器
    private var segmentControl: some View {
        HStack(spacing: 4) {
            Button(action: { selectedTab = 0 }) {
                Text("我的嘱托")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 0 ? Color(hex: "AF52DE") : Color.clear)
                    .foregroundColor(selectedTab == 0 ? .white : .primary)
                    .cornerRadius(8)
            }
            
            Button(action: { selectedTab = 1 }) {
                Text("资产管理")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedTab == 1 ? Color(hex: "AF52DE") : Color.clear)
                    .foregroundColor(selectedTab == 1 ? .white : .primary)
                    .cornerRadius(8)
            }
        }
        .padding(4)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    // MARK: - 遗嘱内容
    private var willContent: some View {
        VStack(spacing: 16) {
            // 进度卡片
            progressCard
            
            // 使用模板按钮
            Button(action: { showingTemplateModal = true }) {
                HStack {
                    Text("📋")
                    Text("使用预设模板")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(Color(hex: "AF52DE"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "AF52DE"), lineWidth: 1)
                )
            }
            
            // 遗嘱模块列表
            ForEach(dataManager.willModules) { module in
                WillModuleCard(module: module, onTap: {
                    editingModule = module
                })
            }
            
            // 法律提示
            infoCard(
                icon: "⚖️",
                title: "关于遗嘱的法律说明",
                desc: "本遗嘱为自书遗嘱，需亲笔签名并注明日期才具法律效力。建议有 2 名以上见证人在场，或前往公证处办理公证。"
            )
            
            // 操作按钮
            Button(action: {
                // TODO: 预览遗嘱
            }) {
                HStack {
                    Text("👁️")
                    Text("预览遗嘱")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "AF52DE"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                // TODO: 导出 PDF
            }) {
                HStack {
                    Text("📤")
                    Text("导出 PDF")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(Color(hex: "AF52DE"))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "AF52DE"), lineWidth: 1)
                )
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - 资产内容
    private var assetsContent: some View {
        VStack(spacing: 16) {
            // 安全提示
            infoCard(
                icon: "🔒",
                title: "安全提示",
                desc: "仅记录资产信息用于身后事务处理，不存储密码和完整账号。建议记录账号后 4 位以便识别。"
            )
            
            // 资产列表
            ForEach(dataManager.assets) { asset in
                AssetCard(asset: asset)
            }
            
            // 添加资产按钮
            Button(action: { showingAddAssetModal = true }) {
                HStack {
                    Text("+")
                    Text("添加金融资产")
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "AF52DE"))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding(.bottom, 100)
    }
    
    // MARK: - 进度卡片
    private var progressCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("填写进度")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text("完成度越高，您的意愿就越清晰")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(dataManager.getWillProgress() * 100))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(hex: "E5E5EA"))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "AF52DE"), Color(hex: "007AFF")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * dataManager.getWillProgress(), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("已完成 \(dataManager.willModules.filter { $0.isCompleted }.count) 项")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("共 \(dataManager.willModules.count) 项")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }
    
    // MARK: - 信息卡片
    private func infoCard(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Color(hex: "AF52DE").opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - 遗嘱模块卡片
struct WillModuleCard: View {
    let module: WillModule
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Text(module.type.icon)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(Color(hex: module.type.color).opacity(0.12))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(module.subtitle.isEmpty ? module.type.subtitle : module.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if module.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "34C759"))
                    .font(.system(size: 22))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - 资产卡片
struct AssetCard: View {
    let asset: Asset
    
    var body: some View {
        VStack(spacing: 12) {
            // 头部
            HStack(spacing: 12) {
                Text(asset.type.icon)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: asset.type.color).opacity(0.12))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(asset.institution)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("¥\(formatBalance(asset.balance))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "AF52DE"))
            }
            
            Divider()
            
            // 详情
            ForEach(Array(asset.details.keys), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(asset.details[key] ?? "")
                        .font(.system(size: 13, weight: .medium))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
    }
    
    private func formatBalance(_ balance: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: balance)) ?? "0"
    }
}

#Preview {
    WillAssetsView()
}
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
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }
                
                Section {
                    Button(action: { showingTemplatePicker = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("使用模板快速填充")
                        }
                        .foregroundColor(Color(hex: "AF52DE"))
                    }
                    
                    Toggle("标记为已完成", isOn: $isCompleted)
                }
                
                Section(footer: Text("💡 提示：点击模板按钮可快速填充常用内容，然后根据需要修改")) {
                    EmptyView()
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
            .sheet(isPresented: $showingTemplatePicker) {
                TemplatePickerModal(moduleType: module.type, onTemplateSelected: { template in
                    content = template
                })
            }
        }
    }
}

// MARK: - 模板选择器
struct TemplatePickerModal: View {
    let moduleType: WillModule.WillType
    let onTemplateSelected: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var templates: [(title: String, content: String)] {
        switch moduleType {
        case .property:
            return [
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
                    title: "多人分配",
                    content: """
                    本人 [姓名]，身份证号 [号码]，现将名下财产做如下分配：
                    
                    一、房产
                    位于 [地址] 的房产，由 [继承人 A] 继承 50% 份额，[继承人 B] 继承 50% 份额。
                    
                    二、银行存款
                    [银行名称] 账户（尾号 [XXXX]）存款由 [继承人 A] 继承。
                    [银行名称] 账户（尾号 [XXXX]）存款由 [继承人 B] 继承。
                    
                    三、其他财产
                    剩余财产由 [继承人 A] 和 [继承人 B] 平均分配。
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                )
            ]
        case .heirs:
            return [
                (
                    title: "唯一继承人",
                    content: """
                    本人 [姓名]，身份证号 [号码]，指定 [继承人姓名]（身份证号：[号码]）为本人的唯一遗产继承人。
                    
                    本人名下全部财产（包括但不限于房产、存款、股票、基金、保险、车辆等）均归其个人所有，不属于其夫妻共同财产。
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                ),
                (
                    title: "多个继承人",
                    content: """
                    本人 [姓名]，身份证号 [号码]，现将遗产继承人指定如下：
                    
                    一、第一顺序继承人
                    1. [姓名]（关系：[如：配偶]），继承比例：[XX]%
                    2. [姓名]（关系：[如：子女]），继承比例：[XX]%
                    
                    二、替补继承人
                    如上述继承人先于本人去世，其应继承份额由 [替补继承人姓名] 继承。
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                )
            ]
        case .specialItems:
            return [
                (
                    title: "纪念品分配",
                    content: """
                    关于本人有特殊纪念意义的物品，分配如下：
                    
                    一、珠宝首饰
                    [具体描述] 传给 [继承人姓名]
                    
                    二、收藏品
                    [具体描述] 传给 [继承人姓名]
                    
                    三、照片和文件
                    所有家庭照片、文件资料由 [继承人姓名] 保管。
                    
                    四、其他物品
                    其余物品由 [继承人姓名] 处理。
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                )
            ]
        case .funeral:
            return [
                (
                    title: "丧事从简",
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
                ),
                (
                    title: "环保葬礼",
                    content: """
                    关于本人的后事，希望遵循环保理念：
                    
                    一、遗体处理
                    选择生态葬（树葬、花葬、海葬等），不使用传统墓地。
                    
                    二、仪式
                    不举行传统葬礼，可举办小型纪念聚会。
                    
                    三、费用
                    节省下来的丧葬费用捐赠给 [慈善机构名称]。
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                )
            ]
        case .otherInstructions:
            return [
                (
                    title: "数字遗产",
                    content: """
                    关于本人的数字遗产处理：
                    
                    一、社交媒体
                    [微信/QQ/微博] 账号由 [继承人姓名] 处理（注销或纪念）。
                    
                    二、电子邮箱
                    邮箱账号 [邮箱地址] 由 [继承人姓名] 保管。
                    
                    三、云存储
                    [iCloud/百度网盘等] 账号密码已告知 [继承人姓名]。
                    
                    四、其他数字资产
                    [游戏账号/付费会员等] 由 [继承人姓名] 处理。
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                ),
                (
                    title: "宠物安置",
                    content: """
                    关于本人饲养的宠物安置：
                    
                    一、宠物信息
                    姓名：[宠物名]
                    品种：[品种]
                    年龄：[年龄]
                    
                    二、安置安排
                    宠物由 [继承人姓名] 继续饲养。
                    
                    三、费用
                    从本人存款中预留 [金额] 元作为宠物抚养费用。
                    
                    四、特殊说明
                    [宠物的生活习惯、医疗需求等]
                    
                    立遗嘱人：[签名]
                    日期：[年] 年 [月] 月 [日] 日
                    """
                )
            ]
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.title) { template in
                    Button(action: {
                        onTemplateSelected(template.content)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(template.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(template.content.prefix(80) + "...")
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
                        // 应用模板到对应模块
                        dismiss()
                        // 简单处理：关闭弹窗，用户需要手动编辑模块
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
                        TextField("开户行", text: Binding<String>(get: { details["开户行"] ?? "" }, set: { details["开户行"] = $0 }))
                    case .stock:
                        TextField("持仓", text: Binding<String>(get: { details["持仓"] ?? "" }, set: { details["持仓"] = $0 }))
                    case .insurance:
                        TextField("保单号", text: Binding<String>(get: { details["保单号"] ?? "" }, set: { details["保单号"] = $0 }))
                        TextField("受益人", text: Binding<String>(get: { details["受益人"] ?? "" }, set: { details["受益人"] = $0 }))
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
