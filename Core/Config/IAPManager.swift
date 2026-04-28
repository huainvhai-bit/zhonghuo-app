//
//  IAPManager.swift
//  终活
//
//  Apple In-App Purchase 管理器
//  使用 StoreKit 2 实现订阅购买
//

import Foundation
import StoreKit

/// IAP 商品类型
enum IAPProductType: String, CaseIterable {
    case monthly = "zhonghuo.month1"
    case yearly = "zhonghuo.year1"
    
    var displayName: String {
        switch self {
        case .monthly: return "月卡会员"
        case .yearly: return "年卡会员"
        }
    }
    
    var subscriptionDuration: IAPSubscriptionDuration {
        switch self {
        case .monthly: return .month
        case .yearly: return .year
        }
    }
}

/// 订阅时长
enum IAPSubscriptionDuration {
    case month
    case year
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .month: return .month
        case .year: return .year
        }
    }
    
    var value: Int {
        return 1
    }
}

/// 购买结果
enum IAPPurchaseResult {
    /// transactionId: 当前事务 ID（每次续订/恢复都会变）
    /// originalTransactionId: 原始订阅事务 ID，整条订阅链不变，用于服务器绑定到 App 账号
    case success(transactionId: String, originalTransactionId: String, expiryDate: Date)
    case pending
    case failure(error: String)
    case cancelled
}

/// IAP 管理器
@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    // MARK: - 发布属性
    @Published var products: [Product] = []
    @Published var purchasedProductIds: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSubscribed: Bool = false
    
    // 商品ID到产品类型的映射
    private var productTypeMap: [String: IAPProductType] = [
        "zhonghuo.month1": .monthly,
        "zhonghuo.year1": .yearly
    ]
    
    // 事务监听任务
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        // 启动事务监听
        transactionListener = listenForTransactions()
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - 公开方法
    
    /// App Store Connect → 订阅产品 ID（须与后台配置逐字一致，含大小写）
    static let expectedSubscriptionProductIdentifiers: [String] = IAPProductType.allCases.map(\.rawValue)

    /// 加载可用商品
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIds = Self.expectedSubscriptionProductIdentifiers
            let wanted = Set(productIds)
            let storeProducts = try await Product.products(for: wanted)

            print("📦 IAP 请求的 Product IDs: \(productIds.joined(separator: ", "))")
            print("📦 App Store 返回 \(storeProducts.count) 个订阅商品 → \(storeProducts.map(\.id).sorted().joined(separator: ", "))")

            let receivedIds = Set(storeProducts.map(\.id))
            let missingIds = wanted.subtracting(receivedIds)
            if !missingIds.isEmpty {
                print("⚠️ IAP 下列 ID 未被 App Store 返回（通常为 ASC 未创建、ID 不符、或未满足协议）：\(missingIds.sorted().joined(separator: ", "))")
            }

            var orderedProducts: [Product] = []
            for productId in productIds {
                if let product = storeProducts.first(where: { $0.id == productId }) {
                    orderedProducts.append(product)
                }
            }

            products = orderedProducts
            isLoading = false

            if storeProducts.isEmpty {
                errorMessage = Self.productsUnavailableDeveloperHint()
                print("❌ IAP: Product.products(for:) 未返回任何商品，请核对 App Store Connect 与 Xcode Scheme（StoreKit 配置 / 沙盒账号）")
            } else {
                print("✅ IAP 商品加载成功：\(products.count) 个")
                for product in products {
                    print("   - \(product.id): \(product.displayPrice)")
                }
            }
        } catch {
            isLoading = false
            errorMessage = "加载商品失败：\(error.localizedDescription)"
            print("❌ IAP 商品加载失败：\(error)")
        }
    }
    
    /// 购买订阅
    /// - Parameter productType: 商品类型
    /// - Returns: 购买结果
    func purchase(_ productType: IAPProductType) async -> IAPPurchaseResult {
        guard let product = products.first(where: { $0.id == productType.rawValue }) else {
            await loadProducts()
            guard let product = products.first(where: { $0.id == productType.rawValue }) else {
                let hint = Self.storeProductUnavailableUserMessage(for: productType)
                errorMessage = hint
                return .failure(error: hint)
            }
            return await performPurchase(product)
        }
        
        return await performPurchase(product)
    }

    /// 当 `Product.products` 拿不到对应 ID 时的说明（Console 与 errorMessage 共用逻辑的一部分）
    nonisolated private static func productsUnavailableDeveloperHint() -> String {
        let ids = IAPProductType.allCases.map(\.rawValue).joined(separator: "、")
        return "未加载到订阅商品。请在 App Store Connect 创建与代码一致的自动续期订阅 ID：\(ids)；签「付费 App」协议并完善银行税务；真机用沙盒 Apple ID；Xcode 可在 Scheme → Run → Options 选 StoreKit 配置文件调试。"
    }

    /// 用户弹窗用（略短）
    nonisolated private static func storeProductUnavailableUserMessage(for type: IAPProductType) -> String {
        let ids = IAPProductType.allCases.map(\.rawValue).joined(separator: "、")
        return "未获取到订阅「\(type.rawValue)」（请求 ID：\(ids)）。请到 App Store Connect 核对产品 ID 与 App 一致、订阅可售且协议/银行已完成；本地可用 StoreKit 配置文件调试。"
    }
    
    /// 执行购买
    private func performPurchase(_ product: Product) async -> IAPPurchaseResult {
        isLoading = true
        errorMessage = nil
        
        do {
            // 显示购买对话框
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 验证交易
                let transaction = try checkVerified(verification)
                
                // 获取订阅过期日期
                let expiryDate = calculateExpiryDate(for: transaction)
                
                // 存储交易信息用于后续验证
                await saveTransactionInfo(transaction)
                
                // 完成交易
                await transaction.finish()
                
                isLoading = false
                purchasedProductIds.insert(product.id)
                isSubscribed = true
                
                let originalId = String(transaction.originalID)
                print("✅ IAP 购买成功：\(product.id), txId=\(transaction.id), originalTxId=\(originalId), 到期日：\(expiryDate)")
                
                return .success(
                    transactionId: String(transaction.id),
                    originalTransactionId: originalId,
                    expiryDate: expiryDate
                )
                
            case .userCancelled:
                isLoading = false
                print("⚠️ 用户取消购买")
                return .cancelled
                
            case .pending:
                isLoading = false
                print("⚠️ 购买待处理")
                return .pending
                
            @unknown default:
                isLoading = false
                return .failure(error: "未知购买结果")
            }
        } catch {
            isLoading = false
            errorMessage = "购买失败：\(error.localizedDescription)"
            print("❌ IAP 购买失败：\(error)")
            return .failure(error: error.localizedDescription)
        }
    }
    
    /// 检查当前订阅状态并写入 MembershipManager（与系统「订阅管理」、恢复购买链路一致）
    func checkSubscriptionStatus() async {
        isLoading = true
        defer { isLoading = false }

        var bestTransaction: Transaction?
        var bestExpiry: Date?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard productTypeMap[transaction.productID] != nil else { continue }

            let expiryDate = calculateExpiryDate(for: transaction)
            guard expiryDate > Date() else { continue }

            if bestExpiry == nil || expiryDate > bestExpiry! {
                bestExpiry = expiryDate
                bestTransaction = transaction
            }
            purchasedProductIds.insert(transaction.productID)
        }

        if let tx = bestTransaction, let exp = bestExpiry {
            isSubscribed = true
            MembershipManager.shared.applySubscriptionFromAppleStore(productId: tx.productID, expiresAt: exp)
            print("📋 StoreKit 有效订阅：\(tx.productID)，到期 \(exp)")
        } else {
            isSubscribed = false
            print("📋 StoreKit：当前无有效订阅权益（已过期或已取消且到期）")
        }
    }

    /// 从 App Store 拉取最新订阅状态并镜像到会员页（用户关闭「管理订阅」页后调用）
    func refreshMirroredMembershipFromStore() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
    
    /// 恢复购买
    func restorePurchases() async {
        isLoading = true
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            isLoading = false
            print("✅ 购买恢复成功")
        } catch {
            isLoading = false
            errorMessage = "恢复购买失败：\(error.localizedDescription)"
            print("❌ 恢复购买失败：\(error)")
        }
    }
    
    /// 获取商品价格
    func price(for productType: IAPProductType) -> String? {
        return products.first(where: { $0.id == productType.rawValue })?.displayPrice
    }
    
    // MARK: - 私有方法
    
    /// 监听交易更新
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { break }
                guard case .verified(let transaction) = result else { continue }
                let productId = transaction.productID
                let handled = await MainActor.run { () -> Bool in
                    guard self.productTypeMap[productId] != nil else { return false }
                    let exp = self.calculateExpiryDate(for: transaction)
                    guard exp > Date() else { return false }
                    self.purchasedProductIds.insert(productId)
                    self.isSubscribed = true
                    MembershipManager.shared.applySubscriptionFromAppleStore(productId: productId, expiresAt: exp)
                    return true
                }
                if handled {
                    await transaction.finish()
                }
            }
        }
    }
    
    /// 验证交易
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw IAPError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    /// 订阅到期时间：仅使用 Apple 提供的 `expirationDate`（含改档、促销、宽限期后的真实到期）。无系统日期时不再用「购买日 + 月/年」推断，避免与 StoreKit 状态不一致。
    private func calculateExpiryDate(for transaction: Transaction) -> Date {
        if let systemExpiry = transaction.expirationDate {
            return systemExpiry
        }
        #if DEBUG
        print("⚠️ IAP: transaction.expirationDate 为空，仅作占位回退（请确认商品为自动续期订阅）")
        #endif
        return transaction.purchaseDate
    }
    
    /// 保存交易信息（用于服务器验证）
    private func saveTransactionInfo(_ transaction: Transaction) async {
        // 保存到本地存储
        let transactionData: [String: Any] = [
            "transactionId": String(transaction.id),
            "productId": transaction.productID,
            "purchaseDate": transaction.purchaseDate.timeIntervalSince1970,
            "expiryDate": calculateExpiryDate(for: transaction).timeIntervalSince1970
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: transactionData) {
            UserDefaults.standard.set(data, forKey: "IAPTransaction")
            print("📦 交易信息已保存：\(transactionData)")
        }
        
        // 发送到服务器验证
        await verifyReceiptWithServer(transaction)
    }
    
    /// 将 Receipt 发送到服务器验证并激活会员
    private func verifyReceiptWithServer(_ transaction: Transaction) async {
        let userId = UserDefaults.standard.string(forKey: "userId") ?? ""
        guard !userId.isEmpty else {
            print("⚠️ 用户未登录，跳过服务器验证")
            return
        }
        
        let memberType: String
        switch transaction.productID {
        case "zhonghuo.month1":
            memberType = "monthly"
        case "zhonghuo.year1":
            memberType = "yearly"
        default:
            memberType = "monthly"
        }
        
        // 构建 GraphQL mutation
        // 把 originalTransactionId 一起送上去，让服务器把订阅绑定到当前 App 账号
        let mutation = """
        mutation ActivateMembership($memberType: String!, $receipt: String!, $originalTransactionId: String) {
            activateMembership(memberType: $memberType, receipt: $receipt, originalTransactionId: $originalTransactionId) {
                success
                isPremium
                memberType
                memberExpireAt
                message
            }
        }
        """
        
        let variables: [String: Any] = [
            "memberType": memberType,
            "receipt": String(transaction.id),
            "originalTransactionId": String(transaction.originalID)
        ]
        
        let apiURL = AppConfig.defaultAPIURL
        guard let url = URL(string: "\(apiURL)/api/graphql.php") else {
            print("❌ 无效的 API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(KeychainManager.shared.getToken() ?? "")", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "query": mutation,
            "variables": variables
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ 服务器响应无效")
                return
            }
            
            if httpResponse.statusCode == 200 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let result = json["data"] as? [String: Any],
                   let activateMembership = result["activateMembership"] as? [String: Any] {
                    
                    let success = activateMembership["success"] as? Bool ?? false
                    if success {
                        print("✅ 服务器会员激活成功")
                        
                        // 更新本地会员过期时间
                        if let expireAtString = activateMembership["memberExpireAt"] as? String {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            if let expireAt = formatter.date(from: expireAtString) {
                                let expiryData: [String: Any] = [
                                    "memberExpireAt": expireAt.timeIntervalSince1970,
                                    "memberType": memberType
                                ]
                                if let data = try? JSONSerialization.data(withJSONObject: expiryData) {
                                    UserDefaults.standard.set(data, forKey: "MemberInfo")
                                }
                            }
                        }
                    } else {
                        let message = activateMembership["message"] as? String ?? "未知错误"
                        print("⚠️ 服务器会员激活失败：\(message)")
                    }
                }
            } else {
                print("❌ 服务器返回错误状态码：\(httpResponse.statusCode)")
            }
        } catch {
            print("❌ 发送 receipt 验证失败：\(error.localizedDescription)")
        }
    }
    
    /// 获取订阅过期日期
    func getSubscriptionExpiryDate() -> Date? {
        guard let data = UserDefaults.standard.data(forKey: "IAPTransaction"),
              let transactionData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let expiryTimestamp = transactionData["expiryDate"] as? TimeInterval else {
            return nil
        }
        return Date(timeIntervalSince1970: expiryTimestamp)
    }
}

// MARK: - 错误类型

enum IAPError: LocalizedError {
    case verificationFailed
    case productNotFound
    case purchaseFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "交易验证失败"
        case .productNotFound:
            return "商品不存在"
        case .purchaseFailed(let message):
            return "购买失败：\(message)"
        }
    }
}
