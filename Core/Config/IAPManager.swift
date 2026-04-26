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
    case monthly = "zhonghuo.monthly"
    case yearly = "zhonghuo.yearly"
    
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
    case success(transactionId: String, expiryDate: Date)
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
        "zhonghuo.monthly": .monthly,
        "zhonghuo.yearly": .yearly
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
    
    /// 加载可用商品
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 获取商品信息
            let productIds = IAPProductType.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: Set(productIds))
            
            // 按顺序排列
            var orderedProducts: [Product] = []
            for productId in productIds {
                if let product = storeProducts.first(where: { $0.id == productId }) {
                    orderedProducts.append(product)
                }
            }
            
            products = orderedProducts
            isLoading = false
            
            print("✅ IAP 商品加载成功：\(products.count) 个")
            for product in products {
                print("   - \(product.id): \(product.displayPrice)")
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
            // 商品未加载，尝试重新加载
            await loadProducts()
            guard let product = products.first(where: { $0.id == productType.rawValue }) else {
                return .failure(error: "商品不存在")
            }
            return await performPurchase(product)
        }
        
        return await performPurchase(product)
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
                
                print("✅ IAP 购买成功：\(product.id), 到期日：\(expiryDate)")
                
                return .success(transactionId: String(transaction.id), expiryDate: expiryDate)
                
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
    
    /// 检查当前订阅状态
    func checkSubscriptionStatus() async {
        isLoading = true
        
        do {
            // 获取所有活跃订阅
            var hasActiveSubscription = false
            var latestExpiryDate: Date?
            
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    // 检查是否是我们的商品
                    if productTypeMap[transaction.productID] != nil {
                        let expiryDate = calculateExpiryDate(for: transaction)
                        
                        if expiryDate > Date() {
                            hasActiveSubscription = true
                            if latestExpiryDate == nil || expiryDate > latestExpiryDate! {
                                latestExpiryDate = expiryDate
                            }
                            purchasedProductIds.insert(transaction.productID)
                        }
                    }
                }
            }
            
            isSubscribed = hasActiveSubscription
            isLoading = false
            
            print("📋 订阅状态检查：\(hasActiveSubscription ? "已订阅" : "未订阅")")
            if let expiry = latestExpiryDate {
                print("   到期日：\(expiry)")
            }
            
        } catch {
            isLoading = false
            print("❌ 订阅状态检查失败：\(error)")
        }
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
                
                if case .verified(let transaction) = result {
                    // 处理更新的交易
                    let expiryDate = await self.calculateExpiryDate(for: transaction)
                    
                    if expiryDate > Date() {
                        await MainActor.run {
                            self.purchasedProductIds.insert(transaction.productID)
                            self.isSubscribed = true
                        }
                    }
                    
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
    
    /// 计算过期日期
    private func calculateExpiryDate(for transaction: Transaction) -> Date {
        // 获取原始订阅日期
        let purchaseDate = transaction.purchaseDate
        
        // 获取订阅时长
        let productType = productTypeMap[transaction.productID] ?? .monthly
        let duration = productType.subscriptionDuration
        
        // 计算过期日期
        let calendar = Calendar.current
        let expiryDate = calendar.date(byAdding: duration.calendarComponent, value: duration.value, to: purchaseDate) ?? purchaseDate
        
        return expiryDate
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
        case "zhonghuo.monthly":
            memberType = "monthly"
        case "zhonghuo.yearly":
            memberType = "yearly"
        default:
            memberType = "monthly"
        }
        
        // 构建 GraphQL mutation
        let mutation = """
        mutation ActivateMembership($memberType: String!, $receipt: String!) {
            activateMembership(memberType: $memberType, receipt: $receipt) {
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
            "receipt": String(transaction.id)  // 发送 transactionId
        ]
        
        let apiURL = AppConfig.defaultAPIURL
        guard let url = URL(string: "\(apiURL)/graphql.php") else {
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
