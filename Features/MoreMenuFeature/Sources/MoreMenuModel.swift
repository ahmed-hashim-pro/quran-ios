//
//  MoreMenuModel.swift
//
//
//  Created by Afifi, Mohamed on 8/29/21.
//

public struct MoreMenuModel {
    // MARK: Lifecycle

    public init(isWordPointerActive: Bool, isFocusModeActive: Bool = false, state: MoreMenuControlsState) {
        self.isWordPointerActive = isWordPointerActive
        self.isFocusModeActive = isFocusModeActive
        self.state = state
    }

    // MARK: Public

    public var isWordPointerActive: Bool
    public var isFocusModeActive: Bool
    public var state: MoreMenuControlsState
}

public enum ConfigState {
    case alwaysOn
    case alwaysOff
    case conditional
}

public struct MoreMenuControlsState {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var goTo = ConfigState.alwaysOff
    public var search = ConfigState.alwaysOff
    public var mushafPrint = ConfigState.alwaysOff
    public var mode = ConfigState.conditional
    public var translationsSelection = ConfigState.conditional
    public var arabicText = ConfigState.conditional
    public var wordPointer = ConfigState.conditional
    public var linePageDisplay = ConfigState.alwaysOff
    #if QURAN_SYNC
    public var ayahIndicators = ConfigState.alwaysOff
    #endif
    public var orientation = ConfigState.conditional
    /// quran_android's Lock orientation and Landscape. While locked, the rotate buttons are disabled.
    public var orientationLock = ConfigState.alwaysOff
    public var fontSize = ConfigState.conditional
    public var twoPages = ConfigState.conditional
    /// Shown only where two pages are, and usable only while they are on.
    public var splitPageAndTranslation = ConfigState.alwaysOff
    public var verticalScrolling = ConfigState.conditional
    public var markerPopups = ConfigState.conditional
    public var audioManager = ConfigState.alwaysOff
    public var theme = ConfigState.conditional
    /// quran_android's Focus mode, which hides the reader's bars until it is turned off.
    public var focusMode = ConfigState.alwaysOff
    /// quran_android's Advanced Options, which the host app provides.
    public var advancedOptions = ConfigState.alwaysOff
}
