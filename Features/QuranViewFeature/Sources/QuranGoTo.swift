//
//  QuranGoTo.swift
//  QuranEngine
//

import Localization
import NoorUI
import QuranKit
import QuranLocalization
import SwiftUI
import UIKit
import UIx

enum QuranGoToTarget: Equatable {
    case page(Page)
    case ayah(AyahNumber)
}

/// Reads a whole number typed with Latin, Arabic-Indic or Persian digits, as Arabic and Persian keyboards type them.
func typedNumber(_ text: String) -> Int? {
    let digits = text.trimmingCharacters(in: .whitespaces).unicodeScalars.map { scalar -> String in
        switch scalar.value {
        case 0x660 ... 0x669: String(scalar.value - 0x660)
        case 0x6F0 ... 0x6F9: String(scalar.value - 0x6F0)
        default: String(scalar)
        }
    }.joined()
    guard !digits.isEmpty, digits.allSatisfy({ $0.isASCII && $0.isNumber }) else {
        return nil
    }
    return Int(digits)
}

/// quran_android's Go to page: a page, or a surah and ayah.
struct QuranGoToForm: Equatable {
    // MARK: Lifecycle

    init(start: Page) {
        pageText = NumberFormatter.shared.format(start.pageNumber)
        sura = start.startSura
    }

    // MARK: Internal

    enum Mode: Hashable {
        case page
        case ayah
    }

    var mode = Mode.page
    var pageText: String
    var ayahText = NumberFormatter.shared.format(1)
    var sura: Sura {
        didSet {
            if sura != oldValue {
                ayahText = NumberFormatter.shared.format(1)
            }
        }
    }

    var quran: Quran { sura.quran }

    var limit: Int {
        switch mode {
        case .page: quran.pages.count
        case .ayah: sura.lastVerse.ayah
        }
    }

    var target: QuranGoToTarget? {
        switch mode {
        case .page:
            typedNumber(pageText).flatMap { Page(quran: quran, pageNumber: $0) }.map(QuranGoToTarget.page)
        case .ayah:
            typedNumber(ayahText).flatMap { AyahNumber(quran: quran, sura: sura.suraNumber, ayah: $0) }.map(QuranGoToTarget.ayah)
        }
    }

    /// Something is typed, but it is not in this print or surah.
    var isOutOfRange: Bool {
        let text = mode == .page ? pageText : ayahText
        return !text.trimmingCharacters(in: .whitespaces).isEmpty && target == nil
    }
}

@MainActor
struct QuranGoToBuilder {
    func build(start: Page, onGo: @escaping (QuranGoToTarget) -> Void) -> UIViewController {
        let controller = UIHostingController(rootView: QuranGoToView(form: QuranGoToForm(start: start), onGo: onGo))
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        return controller
    }
}

struct QuranGoToView: View {
    // MARK: Internal

    @State var form: QuranGoToForm
    let onGo: (QuranGoToTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(lAndroid("menu_jump"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                CloseButton()
            }

            Picker(lAndroid("menu_jump"), selection: $form.mode) {
                Text(lAndroid("quran_page")).tag(QuranGoToForm.Mode.page)
                Text(l("surah")).tag(QuranGoToForm.Mode.ayah)
            }
            .pickerStyle(.segmented)

            switch form.mode {
            case .page:
                numberField(lAndroid("quran_page"), text: $form.pageText)
            case .ayah:
                Picker(l("surah"), selection: $form.sura) {
                    ForEach(form.quran.suras) { sura in
                        Text("\(sura.localizedSuraNumber). \(sura.localizedName())").tag(sura)
                    }
                }
                .pickerStyle(.menu)
                numberField(l("ayah"), text: $form.ayahText)
            }

            Button(action: go) {
                Text(lAndroid("dialog_ok"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(form.target == nil)

            Spacer(minLength: 0)
        }
        .padding()
        .onAppear { isFieldFocused = true }
    }

    // MARK: Private

    @FocusState private var isFieldFocused: Bool

    private var rangeText: String {
        "\(NumberFormatter.shared.format(1))–\(NumberFormatter.shared.format(form.limit))"
    }

    private func numberField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondaryLabel)
            HStack {
                TextField(title, text: text)
                    .keyboardType(.numberPad)
                    .font(.title2.bold())
                    .focused($isFieldFocused)
                    .onSubmit(go)
                    .onChange(of: isFieldFocused) { focused in
                        // The field starts filled in, so typing replaces it rather than adding to it.
                        if focused {
                            DispatchQueue.main.async {
                                UIApplication.shared.sendAction(#selector(UIResponder.selectAll(_:)), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                Text(rangeText)
                    .monospacedDigit()
                    .foregroundColor(form.isOutOfRange ? .red : .secondaryLabel)
                    .accessibilityLabel(rangeText)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondarySystemBackground))
        }
    }

    private func go() {
        if let target = form.target {
            onGo(target)
        }
    }
}
