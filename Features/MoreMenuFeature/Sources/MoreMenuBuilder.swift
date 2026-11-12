//
//  MoreMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import SwiftUI
import UIKit

@MainActor
public struct MoreMenuBuilder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func build(withListener listener: MoreMenuListener, model: MoreMenuModel) -> UIViewController {
        let viewModel = MoreMenuViewModel(model: model)
        let viewController = MoreMenuController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }

    /// The Themes & Settings sheet, which quran_android's reader bar opens as Settings.
    /// It offers Advanced Options only when `openAdvancedOptions` is given.
    public func buildThemeSettings(
        showFontSize: Bool,
        showArabicFontSize: Bool,
        openAdvancedOptions: (() -> Void)?
    ) -> UIViewController {
        let controller = ThemeSettingsController(rootView: MoreMenuThemeSettingsView(
            showFontSize: showFontSize,
            showArabicFontSize: showArabicFontSize,
            openAdvancedOptions: openAdvancedOptions
        ))
        controller.modalPresentationStyle = .formSheet
        return controller
    }
}
