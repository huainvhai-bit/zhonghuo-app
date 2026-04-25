//
//  LegalDisclosureView.swift
//  终活
//
//  电子遗嘱效力说明（V2.0.0 法律合规）
//  功能：《民法典》第1134-1144条说明
//

import SwiftUI

struct LegalDisclosureView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    // 标题
                    Text(L10n.text(
                        "电子遗嘱效力说明",
                        en: "Electronic Will Validity",
                        ja: "電子遺言の有効性",
                        ko: "전자 유언 효력 안내"
                    ))
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    // 法律依据
                    legalSection(
                        title: L10n.text("法律依据", en: "Legal Basis", ja: "法的根拠", ko: "법적 근거"),
                        content: L10n.text("""
                        根据《中华人民共和国民法典》：

                        • 第1134条：遗嘱形式包括公证遗嘱、自书遗嘱、代书遗嘱、录音遗嘱、口头遗嘱
                        • 第1137条：以录音录像形式立的遗嘱，应当有两个以上见证人在场见证
                        • 第1133条：自然人可以立遗嘱将个人财产指定由法定继承人中的一人或者数人继承
                        • 第1144条：遗嘱人可以指定遗嘱执行人
                        """, en: """
                        Under the Civil Code of the People's Republic of China:

                        • Article 1134: A will may take the form of notarized, handwritten, recorded, oral, or other lawful formats.
                        • Article 1137: A recorded or videotaped will must be witnessed by at least two witnesses.
                        • Article 1133: A natural person may designate one or more statutory heirs to inherit personal property.
                        • Article 1144: The testator may appoint an executor.
                        """, ja: """
                        中華人民共和国民法典によれば：

                        • 第1134条：遺言の形式には、公正証書遺言、自筆証書遺言、代筆遺言、録音遺言、口頭遺言などが含まれます。
                        • 第1137条：録音・録画形式の遺言には、2人以上の証人の立会いが必要です。
                        • 第1133条：自然人は、個人財産を法定相続人の一人または複数人に相続させることができます。
                        • 第1144条：遺言者は遺言執行者を指定できます。
                        """, ko: """
                        중화인민공화국 민법전에 따르면:

                        • 제1134조: 유언의 형식에는 공증 유언, 자필 유언, 대필 유언, 녹음 유언, 구두 유언이 포함됩니다.
                        • 제1137조: 녹음 또는 영상 형태의 유언은 두 명 이상의 증인이 입회해야 합니다.
                        • 제1133조: 자연인은 개인 재산을 법정상속인 중 한 명 또는 여러 명에게 상속하도록 지정할 수 있습니다.
                        • 제1144조: 유언자는 유언 집행인을 지정할 수 있습니다.
                        """)
                    )
                    
                    // 电子遗嘱有效性
                    legalSection(
                        title: L10n.text("电子遗嘱有效性", en: "Digital Will Validity", ja: "電子遺言の有効性", ko: "전자 유언 효력"),
                        content: L10n.text("""
                        ✅ 本应用立遗嘱方式符合《民法典》第1136条：
                        • 内容真实：用户自愿输入，内容真实反映意愿
                        • 形式合规：遗嘱内容完整，包括财产清单、继承人信息
                        • 时间戳：系统记录遗嘱创建/修改时间
                        • 用户认证：登录用户方可操作，身份可追溯

                        ⚠️ 重要提示：
                        • 本应用遗嘱为参考模板，建议结合公证遗嘱使用
                        • 涉及房产、大额资产继承，建议前往公证处办理公证遗嘱
                        • 遗嘱执行过程中，建议聘请专业律师提供法律咨询
                        """, en: """
                        ✅ This will workflow is aligned with Article 1136 of the Civil Code:
                        • Truthful content: entered voluntarily by the user
                        • Complete format: includes assets and heirs
                        • Timestamped: creation and modification times are recorded
                        • Authenticated: only signed-in users can operate, making identity traceable

                        ⚠️ Important:
                        • This app provides reference templates; use together with notarized wills when appropriate
                        • For real estate or large assets, notarization is strongly recommended
                        • For execution, consider consulting a qualified lawyer
                        """, ja: """
                        ✅ 本アプリの遺言作成方法は民法典第1136条に沿っています：
                        • 真実性：ユーザーが自発的に入力した内容
                        • 形式の整合性：財産一覧や相続人情報を含む完全な内容
                        • タイムスタンプ：作成・更新日時を記録
                        • ユーザー認証：ログインユーザーのみ操作可能で、追跡可能

                        ⚠️ 重要：
                        • 本アプリの遺言は参考テンプレートです。公正証書遺言との併用を推奨します。
                        • 不動産や高額資産の相続は、公証役場での公証をおすすめします。
                        • 執行時には、専門の弁護士への相談を検討してください。
                        """, ko: """
                        ✅ 이 앱의 유언 작성 방식은 민법 제1136조에 부합합니다:
                        • 진실성: 사용자가 자발적으로 입력한 내용
                        • 형식 적합성: 자산 목록과 상속인 정보를 포함
                        • 타임스탬프: 생성/수정 시간이 기록됨
                        • 사용자 인증: 로그인한 사용자만 조작 가능하여 추적 가능

                        ⚠️ 중요:
                        • 본 앱의 유언은 참고용 템플릿입니다. 공증 유언과 함께 사용하시길 권장합니다.
                        • 부동산 또는 고액 자산은 공증을 권장합니다.
                        • 집행 과정에서는 전문 변호사 상담을 고려하세요.
                        """)
                    )
                    
                    // 电子签名法
                    legalSection(
                        title: L10n.text("电子签名法", en: "Electronic Signature Law", ja: "電子署名法", ko: "전자서명법"),
                        content: L10n.text("""
                        根据《中华人民共和国电子签名法》：

                        • 第14条：可靠的电子签名与手写签名或者盖章具有同等的法律效力
                        • 第13条：电子签名同时符合下列条件的，视为可靠的电子签名：
                          1. 电子签名用于签署的文件为签名人本人
                          2. 签名时电子签名制作数据仅由签名人控制
                          3. 签名后对电子签名的任何改动能够被发现
                          4. 签名后对数据电文内容和形式的任何改动能够被发现

                        本应用使用：
                        • 用户账号认证（身份唯一性）
                        • 时间戳服务（防篡改）
                        • 操作日志记录（可追溯）
                        """, en: """
                        Under the Electronic Signature Law of the People's Republic of China:

                        • Article 14: A reliable electronic signature has the same legal effect as a handwritten signature or seal.
                        • Article 13: An electronic signature is deemed reliable when it meets all of the following:
                          1. It is used by the signer alone
                          2. The signature creation data is controlled only by the signer
                          3. Any change to the signature after signing can be detected
                          4. Any change to the data message content or form after signing can be detected

                        This app uses:
                        • Account authentication
                        • Timestamping to prevent tampering
                        • Operation logs for traceability
                        """, ja: """
                        中華人民共和国電子署名法によれば：

                        • 第14条：信頼できる電子署名は、手書き署名または押印と同等の法的効力を持ちます。
                        • 第13条：以下の条件をすべて満たす電子署名は、信頼できる電子署名とみなされます。
                          1. 署名者本人のみが使用すること
                          2. 署名作成データが署名者本人のみの管理下にあること
                          3. 署名後の改変が検知できること
                          4. データ内容や形式の改変が検知できること

                        本アプリでは以下を使用します：
                        • アカウント認証
                        • タイムスタンプ
                        • 操作ログ
                        """, ko: """
                        중화인민공화국 전자서명법에 따르면:

                        • 제14조: 신뢰할 수 있는 전자서명은 자필 서명 또는 날인과 동일한 법적 효력을 가집니다.
                        • 제13조: 다음 조건을 모두 충족하면 신뢰할 수 있는 전자서명으로 간주됩니다.
                          1. 서명자 본인만 사용
                          2. 서명 생성 데이터가 서명자만의 통제 하에 있음
                          3. 서명 후 변경을 감지할 수 있음
                          4. 데이터 내용과 형식의 변경을 감지할 수 있음

                        이 앱에서는 다음을 사용합니다:
                        • 계정 인증
                        • 변조 방지를 위한 타임스탬프
                        • 추적 가능한 작업 로그
                        """)
                    )
                    
                    // 见证人资质
                    legalSection(
                        title: L10n.text("见证人资质要求", en: "Witness Requirements", ja: "証人の要件", ko: "증인 자격 요건"),
                        content: L10n.text("""
                        根据《民法典》第1140条，下列人员不能作为遗嘱见证人：

                        ❌ 无行为能力人、限制行为能力人
                        ❌ 继承人、受遗赠人
                        ❌ 与继承人、受遗赠人有利害关系的人

                        ✅ 本应用见证人审核流程：
                        1. 见证人需实名认证（身份证号 + 手机号）
                        2. 见证人需确认无利益冲突
                        3. 见证人需在场见证并电子签名
                        4. 见证记录永久存证（区块链存证，规划中）
                        """, en: """
                        Under Article 1140 of the Civil Code, the following persons cannot serve as witnesses:

                        ❌ Persons without or with limited civil capacity
                        ❌ Heirs or recipients under the will
                        ❌ Persons with interests related to heirs or recipients

                        ✅ Witness review flow in this app:
                        1. Real-name verification is required
                        2. No conflict of interest must be confirmed
                        3. Witnesses must be present and sign electronically
                        4. Witness records are permanently stored
                        """, ja: """
                        民法典第1140条によれば、以下の者は遺言の証人になれません。

                        ❌ 行為能力のない者、制限行為能力者
                        ❌ 相続人、受遺者
                        ❌ 相続人や受遺者と利害関係のある者

                        ✅ 本アプリの証人審査フロー：
                        1. 本人確認が必要です
                        2. 利益相反がないことを確認します
                        3. 証人は立ち会いの上で電子署名します
                        4. 記録は永続保存されます
                        """, ko: """
                        민법 제1140조에 따라 다음 사람은 유언 증인이 될 수 없습니다:

                        ❌ 의사능력이 없거나 제한된 사람
                        ❌ 상속인, 유증자
                        ❌ 상속인 또는 유증자와 이해관계가 있는 사람

                        ✅ 이 앱의 증인 검증 절차:
                        1. 실명 인증 필요
                        2. 이해상충 없음 확인
                        3. 증인은 현장 입회 후 전자서명
                        4. 증인 기록은 영구 보관
                        """)
                    )
                    
                    // 适用场景
                    legalSection(
                        title: L10n.text("适用场景", en: "Recommended Use Cases", ja: "適用シーン", ko: "권장 사용 상황"),
                        content: L10n.text("""
                        ✅ 推荐使用：
                        • 小额财产继承
                        • 动产（存款、车辆、贵重物品）
                        • 数字资产（虚拟货币、游戏账号）
                        • 遗产分配意向表达

                        ⚠️ 建议公证：
                        • 不动产（房产、土地）
                        • 大额资产（公司股权、信托产品）
                        • 复杂继承（多子女、再婚家庭）
                        • 涉外继承（外国人、境外资产）
                        """, en: """
                        ✅ Recommended for:
                        • Small-value asset inheritance
                        • Movable assets (cash, vehicles, valuables)
                        • Digital assets (crypto, game accounts)
                        • Expressing inheritance intent

                        ⚠️ Notarization recommended for:
                        • Real estate (houses, land)
                        • Large assets (equity, trust products)
                        • Complex inheritance (multiple children, blended families)
                        • Cross-border inheritance
                        """, ja: """
                        ✅ 推奨使用シーン：
                        • 少額財産の相続
                        • 動産（預金、車、貴重品）
                        • デジタル資産（仮想通貨、ゲームアカウント）
                        • 相続意向の表明

                        ⚠️ 公証を推奨：
                        • 不動産（土地、建物）
                        • 高額資産（株式、信託商品）
                        • 複雑な相続（複数子、再婚家庭）
                        • 海外関連の相続
                        """, ko: """
                        ✅ 권장 사용:
                        • 소액 자산 상속
                        • 동산(예금, 차량, 귀중품)
                        • 디지털 자산(가상화폐, 게임 계정)
                        • 상속 의사 표현

                        ⚠️ 공증 권장:
                        • 부동산(주택, 토지)
                        • 고액 자산(지분, 신탁 상품)
                        • 복잡한 상속(다자녀, 재혼 가정)
                        • 해외 관련 상속
                        """)
                    )
                    
                    // 法律声明
                    legalSection(
                        title: L10n.text("法律声明", en: "Legal Disclaimer", ja: "法的免責事項", ko: "법적 고지"),
                        content: L10n.text("""
                        本应用提供的遗嘱模板仅供参考，不构成法律意见。

                        使用本应用立遗嘱，视为您已阅读并接受以下条款：
                        1. 遗嘱内容由您本人真实意愿表达
                        2. 您已完全理解遗嘱法律效力
                        3. 您已知悉电子遗嘱的局限性
                        4. 如有疑问，建议咨询专业律师

                        本应用不对遗嘱的法律效力承担保证责任。
                        """, en: """
                        The will templates provided by this app are for reference only and do not constitute legal advice.

                        By using this app to create a will, you acknowledge and accept:
                        1. The will reflects your true intentions
                        2. You fully understand the legal effect of a will
                        3. You are aware of the limitations of digital wills
                        4. You should consult a qualified lawyer if needed

                        This app does not guarantee the legal validity of any will.
                        """, ja: """
                        本アプリが提供する遺言テンプレートは参考用であり、法的助言ではありません。

                        本アプリで遺言を作成することにより、以下の内容に同意したものとみなされます。
                        1. 遺言内容はご本人の真意を反映しています
                        2. 遺言の法的効力を十分に理解しています
                        3. 電子遺言の限界を理解しています
                        4. 必要に応じて専門の弁護士へ相談してください

                        本アプリは遺言の法的有効性を保証しません。
                        """, ko: """
                        이 앱이 제공하는 유언 템플릿은 참고용이며 법률 자문이 아닙니다.

                        이 앱으로 유언을 작성하면 다음을 읽고 동의한 것으로 간주됩니다:
                        1. 유언 내용은 본인의 진정한 의사를 반영합니다
                        2. 유언의 법적 효력을 충분히 이해했습니다
                        3. 전자 유언의 한계를 알고 있습니다
                        4. 필요 시 전문 변호사와 상담해야 합니다

                        이 앱은 유언의 법적 효력을 보장하지 않습니다.
                        """)
                    )
                    
                    Spacer()
                    
                    // 返回按钮
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text(L10n.text("我已阅读并理解", en: "I Have Read and Understood", ja: "内容を読み理解しました", ko: "읽었으며 이해했습니다"))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color( "6366F1"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
        }
            .background(Color("F5F5F7"))
            .navigationTitle(L10n.text("电子遗嘱效力", en: "Digital Will Validity", ja: "電子遺言の有効性", ko: "전자 유언 효력"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .stackNavigationStyle()
    }
    
    // MARK: - 法律章节组件
    func legalSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color("1F2937"))
                .padding(.top, 16)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(Color("374151"))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 预览
struct LegalDisclosureView_Previews: PreviewProvider {
    static var previews: some View {
        LegalDisclosureView()
    }
}
