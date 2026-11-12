//
//  MoreMenuThemeSettings.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-25.
//

import Combine
import Localization
import NoorUI
import QuranText
import SwiftUI
import UIx

final class ThemeSettingsController<V: View>: UIHostingController<V> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil

        if let sheetPresentationController {
            sheetPresentationController.prefersGrabberVisible = true
            sheetPresentationController.prefersEdgeAttachedInCompactHeight = true
            sheetPresentationController.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheetPresentationController.detents = [.medium(), .large()]

            // Keep the SwiftUI scroll view and the sheet's detent gesture independent.
            // UIKit otherwise adjusts the scroll view from _UISheetInteraction while
            // live theme changes are relaying out that same scroll view.
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = nil
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize
    }
}

struct MoreMenuThemeSettingsMenuItem: View {
    let showFontSize: Bool
    let showArabicFontSize: Bool
    var openAdvancedOptions: (() -> Void)?

    @Environment(\.navigator) private var navigator
    @State private var viewController: UIViewController?

    var body: some View {
        Button {
            // capture the window before dismissing
            let window = viewController?.view.window
            navigator?.dismiss {
                let controller = ThemeSettingsController(rootView: themeSettingsView())
                controller.modalPresentationStyle = .formSheet

                let parentVC = window?.rootViewController?.deepPresentedViewController()
                parentVC?.present(controller, animated: true)
            }
        } label: {
            NoorListItem(
                title: .text(l("menu.theme_settings")),
                accessory: .disclosureIndicator
            )
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(BackgroundHighlightingStyle())
        .background(Color.systemBackground)
        UIViewControllerReader(viewController: $viewController)
    }

    private func themeSettingsView() -> some View {
        MoreMenuThemeSettingsView(
            showFontSize: showFontSize,
            showArabicFontSize: showArabicFontSize,
            openAdvancedOptions: openAdvancedOptions
        )
    }
}

private struct SectionHeader: View {
    let header: String
    var body: some View {
        Text(header)
            .font(.headline)
    }
}

private struct AppearanceModeSelectorButton: View {
    @Binding var selectedAppearance: AppearanceMode
    var body: some View {
        DropdownButton(items: AppearanceMode.allCases, selectedItem: $selectedAppearance) { appearance in
            Label(appearance.localizedName, systemImage: appearance.systemImageName)
        }
    }
}

private struct FontSizeView: View {
    let label: String
    let labelWidth: CGFloat
    @Binding var size: FontSize
    @Binding var labelSize: CGSize

    var body: some View {
        HStack(spacing: 30) {
            Text(label)
                .fixedSize()
                .onSizeChange {
                    labelSize = $0
                }
                .frame(width: labelWidth, alignment: .leading)

            FontSizeStepper(fontSize: $size)
        }
    }
}

/// quran_android's Advanced Options: importing and exporting bookmarks, which the host app does.
private struct AdvancedOptionsRow: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            NoorListItem(
                title: .text(lAndroid("prefs_category_advanced")),
                subtitle: .init(text: .text(lAndroid("prefs_category_advanced_summary")), location: .bottom),
                accessory: .disclosureIndicator
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct NightBrightnessSettings: View {
    @Binding var text: Int
    @Binding var background: Int

    var body: some View {
        VStack(alignment: .leading) {
            SectionHeader(header: lAndroid("prefs_night_mode_title"))

            LevelSlider(
                title: lAndroid("prefs_night_mode_text_brightness_title"),
                subtitle: lAndroid("prefs_night_mode_text_brightness_summary"),
                value: $text,
                range: NightBrightness.textRange,
                scale: NightBrightness.textRange.upperBound
            )

            LevelSlider(
                title: lAndroid("prefs_night_mode_background_brightness_title"),
                subtitle: lAndroid("prefs_night_mode_background_brightness_summary"),
                value: $background,
                range: NightBrightness.backgroundRange,
                scale: NightBrightness.textRange.upperBound
            )
        }
    }
}

struct MoreMenuThemeSettingsView: View {
    @StateObject var viewModel = MoreMenuThemeSettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    let showFontSize: Bool
    let showArabicFontSize: Bool
    var openAdvancedOptions: (() -> Void)?

    @State private var arabicLabelSize: CGSize = .zero
    @State private var translationLabelSize: CGSize = .zero

    @ScaledMetric var compactVerticalPadding = 3.0

    var fontSizeLabelWidth: CGFloat {
        max(arabicLabelSize.width, translationLabelSize.width)
    }

    var body: some View {
        PreferredContentSizeMatchesScrollView {
            ScrollView {
                VStack {
                    HStack {
                        Text(l("menu.theme_settings"))
                            .font(.title)
                            .fontWeight(.semibold)
                        Spacer()
                        CloseButton()
                    }

                    if showFontSize {
                        if showArabicFontSize {
                            FontSizeView(
                                label: l("menu.arabicFontSize"),
                                labelWidth: fontSizeLabelWidth,
                                size: $viewModel.arabicFontSize,
                                labelSize: $arabicLabelSize
                            )

                            Divider()
                                .padding(.vertical, compactVerticalPadding)
                        }

                        FontSizeView(
                            label: l("menu.translationFontSize"),
                            labelWidth: fontSizeLabelWidth,
                            size: $viewModel.translationFontSize,
                            labelSize: $translationLabelSize
                        )
                    }

                    Divider()
                        .padding(.vertical, compactVerticalPadding)

                    VStack(spacing: 0) {
                        HStack {
                            SectionHeader(header: l("theme.styles"))
                            Spacer()

                            AppearanceModeSelectorButton(selectedAppearance: $viewModel.appearanceMode)
                        }
                        .padding(.horizontal)

                        ThemeStyleSelector(selectedStyle: $viewModel.themeStyle)
                    }

                    Divider()
                        .padding(.vertical, compactVerticalPadding)

                    NightBrightnessSettings(text: $viewModel.nightTextBrightness, background: $viewModel.nightBackgroundBrightness)
                        // Like quran_android, the levels only apply, and only change, in night mode.
                        .disabled(!(colorScheme == .dark || viewModel.themeStyle == .quiet))

                    if let openAdvancedOptions {
                        Divider()
                            .padding(.vertical, compactVerticalPadding)

                        AdvancedOptionsRow(action: openAdvancedOptions)
                    }
                }
                .padding()
            }
        }
        .background(.thickMaterial)
    }
}

#Preview {
    VStack {
        Section {
            MoreMenuThemeSettingsMenuItem(showFontSize: true, showArabicFontSize: true)
        }

        MoreMenuThemeSettingsView(showFontSize: false, showArabicFontSize: true)
    }
}
