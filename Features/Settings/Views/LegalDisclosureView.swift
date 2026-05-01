//
//  LegalDisclosureView.swift
//  安心记
//
//  重要事项说明
//

import SwiftUI

struct LegalDisclosureView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.text(
                        "重要事项说明",
                        en: "Important Notes",
                        ja: "重要事項の説明",
                        ko: "중요 사항 안내"
                    ))
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                    infoSection(
                        title: L10n.text("功能定位", en: "Purpose", ja: "機能の位置づけ", ko: "기능 목적"),
                        content: L10n.text("""
                        安心记用于帮助用户记录个人重要事项、资产线索和家庭留言。

                        App 不会根据未签到、未操作、定位状态或其他条件自动发送任何内容，也不会自动报警、自动通知家人或判断用户是否失联。
                        """, en: """
                        This app helps users record important personal notes, asset references, and family messages.

                        The app does not automatically send any content, trigger alarms, notify family members, or determine whether a user is missing based on missed check-ins, inactivity, location, or any other condition.
                        """, ja: """
                        このアプリは、個人の重要事項、資産に関するメモ、家族向けメッセージの記録を支援します。

                        未チェックイン、未操作、位置情報などを条件に、内容を自動送信したり、警報を出したり、家族へ自動通知したり、行方不明を判断したりすることはありません。
                        """, ko: """
                        이 앱은 개인의 중요 사항, 자산 참고 정보, 가족 메시지를 기록하는 데 도움을 줍니다.

                        체크인 누락, 미사용, 위치 상태 등을 기준으로 내용을 자동 전송하거나, 알림을 자동 발송하거나, 사용자의 실종 여부를 판단하지 않습니다.
                        """)
                    )

                    infoSection(
                        title: L10n.text("内容性质", en: "Content Nature", ja: "内容の性質", ko: "내용 성격"),
                        content: L10n.text("""
                        App 内的模板和记录仅用于个人整理和家庭沟通参考，不构成法律意见、法律文书或任何自动执行安排。

                        如涉及法律、财产处分或其他专业事项，请咨询具备资质的专业人士。
                        """, en: """
                        Templates and records in the app are for personal organization and family communication only. They do not constitute legal advice, legal documents, or any automatic execution arrangement.

                        For legal, property, or other professional matters, please consult a qualified professional.
                        """, ja: """
                        アプリ内のテンプレートや記録は、個人の整理と家族間の共有の参考用です。法的助言、法的文書、自動実行の取り決めではありません。

                        法律、財産、その他専門的な事項については、資格を有する専門家にご相談ください。
                        """, ko: """
                        앱 내 템플릿과 기록은 개인 정리 및 가족 소통 참고용입니다. 법률 자문, 법적 문서 또는 자동 실행 약정이 아닙니다.

                        법률, 재산 또는 기타 전문 사항은 자격 있는 전문가와 상담하세요.
                        """)
                    )

                    infoSection(
                        title: L10n.text("发送方式", en: "Sending Method", ja: "送信方法", ko: "전송 방식"),
                        content: L10n.text("""
                        文字、语音、视频留言必须由用户主动点击发送。绑定家人只有在 App 内打开并同步后，才能看到用户已手动发送的内容。
                        """, en: """
                        Text, audio, and video messages must be manually sent by the user. Connected family members can only view content that the user has already manually sent after opening and syncing the app.
                        """, ja: """
                        テキスト、音声、動画メッセージはユーザーが手動で送信する必要があります。連携した家族は、アプリを開いて同期した後、ユーザーが手動送信済みの内容のみ確認できます。
                        """, ko: """
                        문자, 음성, 영상 메시지는 사용자가 직접 전송해야 합니다. 연결된 가족은 앱을 열고 동기화한 후 사용자가 직접 보낸 내용만 볼 수 있습니다.
                        """)
                    )

                    Spacer()

                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text(L10n.text("我已阅读并理解", en: "I Have Read and Understood", ja: "内容を読み理解しました", ko: "읽었으며 이해했습니다"))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "6366F1"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle(L10n.text("重要事项说明", en: "Important Notes", ja: "重要事項", ko: "중요 사항"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.string(.done)) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .stackNavigationStyle()
    }

    private func infoSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "6366F1"))

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(5)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
