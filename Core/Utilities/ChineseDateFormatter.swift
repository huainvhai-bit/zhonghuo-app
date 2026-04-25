//
//  ChineseDateFormatter.swift
//  终活
//
//  统一的中文日期格式工具
//

import Foundation

enum ChineseDateFormatter {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter
    }()

    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        return formatter
    }()

    static let dateTimeSecondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm:ss"
        return formatter
    }()

    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy年MM月dd日_HHmm"
        return formatter
    }()
}

extension Date {
    func localizedDateString() -> String {
        localizedFormatter(dateOnly: true).string(from: self)
    }

    func localizedDateTimeString() -> String {
        localizedFormatter(dateOnly: false).string(from: self)
    }

    func chineseDateString() -> String {
        ChineseDateFormatter.dateFormatter.string(from: self)
    }

    func chineseDateTimeString() -> String {
        ChineseDateFormatter.dateTimeFormatter.string(from: self)
    }

    func chineseDateTimeSecondString() -> String {
        ChineseDateFormatter.dateTimeSecondFormatter.string(from: self)
    }

    func chineseFileNameString() -> String {
        ChineseDateFormatter.fileNameFormatter.string(from: self)
    }

    private func localizedFormatter(dateOnly: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        let language = AppLanguageManager.shared.language
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current

        switch language {
        case .chinese:
            formatter.dateFormat = dateOnly ? "yyyy 年 MM 月 dd 日" : "yyyy 年 MM 月 dd 日 HH:mm"
        case .english:
            formatter.dateFormat = dateOnly ? "MMM d, yyyy" : "MMM d, yyyy HH:mm"
        case .japanese:
            formatter.dateFormat = dateOnly ? "yyyy年MM月dd日" : "yyyy年MM月dd日 HH:mm"
        case .korean:
            formatter.dateFormat = dateOnly ? "yyyy년 MM월 dd일" : "yyyy년 MM월 dd일 HH:mm"
        }

        return formatter
    }
}
