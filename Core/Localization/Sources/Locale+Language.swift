//
//  Locale+Language.swift
//

import Foundation

public extension Locale {
    static var preferredLanguageLocale: Locale {
        guard let identifier = NSLocale.preferredLanguages.first else {
            return .current
        }
        return Locale(identifier: identifier)
    }

    var isArabicLanguage: Bool {
        languageCode == "ar"
    }

    /// Separates the parts of a line, such as a surah and its ayah, or a page and its print. Arabic-script
    /// languages take the Arabic comma, attached to the word before it: beside their digits a middle dot
    /// reads as a zero.
    var partSeparator: String {
        usesArabicComma ? "، " : " · "
    }

    var usesArabicComma: Bool {
        languageCode.map(Self.arabicCommaLanguageCodes.contains) ?? false
    }

    private static let arabicCommaLanguageCodes: Set<String> = ["ar", "fa", "ur"]
}
