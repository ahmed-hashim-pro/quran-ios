//
//  QuranView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import NoorUI
import UIKit
import UIx
import ViewConstrainer

@MainActor
protocol QuranViewDelegate: AnyObject {
    func onQuranViewTapped(_ quranView: QuranView)
    func onQuranViewSwipedDownFromTop(_ quranView: QuranView)
}

class QuranView: UIView, UIGestureRecognizerDelegate, UINavigationBarDelegate {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    init() {
        super.init(frame: .zero)
        setUp()
    }

    // MARK: Internal

    weak var delegate: QuranViewDelegate?

    var contentView: UIView?

    let navigationBar = UINavigationBar()
    let navigationItem = UINavigationItem()

    /// quran_android's focus mode brings the hidden bars back with a swipe from the top edge.
    var revealsBarsOnSwipeDownFromTop = false

    /// How far the audio bar, with the reading modes above it, reaches above the window's bottom edge, or 0
    /// while it's hidden.
    var bottomBarsHeight: CGFloat {
        guard let audioView, !audioBarHidden, let window else {
            return 0
        }
        let topBar = readingModeBarView ?? audioView
        let barsTop = topBar.convert(topBar.bounds, to: window).minY
        return max(0, window.bounds.height - barsTop)
    }

    override func layoutSubviews() {
        navigationItem.titleView?.setNeedsLayout()
        super.layoutSubviews()
        configureNavigationBarScrollEdgeEffectIfNeeded()
        configureAudioBarScrollEdgeEffectIfNeeded()
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        .topAttached
    }

    func addWordPointerView(_ wordPointerView: UIView) {
        addAutoLayoutSubview(wordPointerView)
        wordPointerView.vc.edges()
    }

    func addContentView(_ contentView: UIView) {
        self.contentView = contentView
        addAutoLayoutSubview(contentView)
        contentView.vc
            .verticalEdges()
            .horizontalEdges()
        sendSubviewToBack(contentView)
    }

    func addAudioBannerView(_ audioBannerView: UIView) {
        audioView = audioBannerView
        addAutoLayoutSubview(audioBannerView)
        audioBannerView.vc
            .horizontalEdges()
            .bottom()
        updateAudioBarVisibility()
        pinReadingModeBar()
    }

    /// quran_android floats the reading modes over the page, centered 16 points above the audio bar,
    /// and moves them with the bars.
    func addReadingModeBarView(_ barView: UIView) {
        readingModeBarView = barView
        addAutoLayoutSubview(barView)
        NSLayoutConstraint.activate([
            barView.centerXAnchor.constraint(equalTo: centerXAnchor),
            barView.leadingAnchor.constraint(
                greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor,
                constant: Self.readingModeBarSpacing
            ),
        ])
        pinReadingModeBar()
        updateReadingModeBarVisibility()
    }

    func setBarsHidden(_ hidden: Bool, animated: Bool = false, completion: (() -> Void)? = nil) {
        let navigationBarStateChanged = navigationBarHidden != hidden
        let audioBarStateChanged = audioBarHidden != hidden
        navigationBarHidden = hidden
        audioBarHidden = hidden
        configureNavigationBarScrollEdgeEffectIfNeeded()
        configureAudioBarScrollEdgeEffectIfNeeded()

        barsVisibilityAnimationID &+= 1
        let animationID = barsVisibilityAnimationID
        let animateNavigationBar = prepareBarForVisibilityTransition(
            navigationBar,
            hidden: hidden,
            animated: animated,
            stateChanged: navigationBarStateChanged
        )
        let animateAudioBar = prepareBarForVisibilityTransition(
            audioView,
            hidden: hidden,
            animated: animated,
            stateChanged: audioBarStateChanged
        )
        let animateTranslationStrip = prepareBarForVisibilityTransition(
            translationStripView,
            hidden: translationStripHidden,
            animated: animated,
            stateChanged: translationStripShown && navigationBarStateChanged
        )
        let animateReadingModeBar = prepareBarForVisibilityTransition(
            readingModeBarView,
            hidden: hidden,
            animated: animated,
            stateChanged: audioBarStateChanged
        )
        guard animateNavigationBar || animateAudioBar || animateTranslationStrip || animateReadingModeBar else {
            completion?()
            return
        }

        NoorAnimation.animate {
            if animateNavigationBar {
                self.navigationBar.alpha = hidden ? 0 : 1
            }
            if animateAudioBar {
                self.audioView?.alpha = hidden ? 0 : 1
            }
            if animateTranslationStrip {
                self.translationStripView?.alpha = hidden ? 0 : 1
            }
            if animateReadingModeBar {
                self.readingModeBarView?.alpha = hidden ? 0 : 1
            }
        } completion: { [weak self] in
            guard let self, barsVisibilityAnimationID == animationID else { return }
            if animateNavigationBar, navigationBarHidden == hidden {
                updateNavigationBarVisibility()
            }
            if animateAudioBar, audioBarHidden == hidden {
                updateAudioBarVisibility()
            }
            if animateTranslationStrip {
                updateTranslationStripVisibility()
            }
            if animateReadingModeBar, audioBarHidden == hidden {
                updateReadingModeBarVisibility()
            }
            completion?()
        }
    }

    // MARK: - Translation Strip

    func addTranslationStripView(_ stripView: UIView) {
        translationStripView = stripView
        addAutoLayoutSubview(stripView)
        stripView.vc.horizontalEdges()
        stripView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor).isActive = true
        updateTranslationStripVisibility()
    }

    /// quran_android shows the strip in translation mode, while the bars show.
    func setTranslationStripShown(_ shown: Bool) {
        translationStripShown = shown
        translationStripView?.layer.removeAllAnimations()
        updateTranslationStripVisibility()
    }

    func setAudioBarHidden(_ hidden: Bool) {
        audioBarHidden = hidden
        configureAudioBarScrollEdgeEffectIfNeeded()
        audioView?.layer.removeAllAnimations()
        updateAudioBarVisibility()
        readingModeBarView?.layer.removeAllAnimations()
        updateReadingModeBarVisibility()
    }

    func refreshScrollEdgeInteractions() {
        configureNavigationBarScrollEdgeEffectIfNeeded()
        configureAudioBarScrollEdgeEffectIfNeeded()
    }

    @objc
    func onViewTapped(_ sender: UITapGestureRecognizer) {
        for bar in [audioView, translationStripView, readingModeBarView].compactMap({ $0 }) where bar.isUserInteractionEnabled {
            if bar.bounds.contains(sender.location(in: bar)) {
                return
            }
        }
        delegate?.onQuranViewTapped(self)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === swipeDownFromTopGesture {
            let location = swipeDownFromTopGesture.location(in: self)
            let translation = swipeDownFromTopGesture.translation(in: self)
            let start = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
            return revealsBarsOnSwipeDownFromTop
                && isSwipeDownFromTop(start: start, velocity: swipeDownFromTopGesture.velocity(in: self))
        }
        return gestureRecognizer != tapGesture || !isFirstResponder // dismiss bars only if not first responder
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Leaves page turns and scrolling to the content.
        gestureRecognizer === swipeDownFromTopGesture
    }

    func isSwipeDownFromTop(start: CGPoint, velocity: CGPoint) -> Bool {
        start.y <= safeAreaInsets.top + topEdgeSwipeHeight && velocity.y > abs(velocity.x)
    }

    // MARK: Private

    private let tapGesture = UITapGestureRecognizer()
    private let swipeDownFromTopGesture = UIPanGestureRecognizer()
    private let topEdgeSwipeHeight: CGFloat = 32
    private static let readingModeBarSpacing: CGFloat = 16

    private var audioView: UIView?
    private var translationStripView: UIView?
    private var readingModeBarView: UIView?
    private var readingModeBarBottom: NSLayoutConstraint?
    private var translationStripShown = false
    private var navigationBarHidden = false
    private var audioBarHidden = false
    // Prevent an interrupted animation from finalizing a newer visibility request.
    private var barsVisibilityAnimationID = 0
    private var navigationBarScrollEdgeInteraction: (any UIInteraction)?
    private var audioBarScrollEdgeInteraction: (any UIInteraction)?

    private func configureNavigationBarScrollEdgeEffectIfNeeded() {
        guard #available(iOS 26.0, *) else { return }

        guard !navigationBarHidden,
              let scrollView = contentScrollView()
        else {
            if let interaction = navigationBarScrollEdgeInteraction {
                navigationBar.removeInteraction(interaction)
                navigationBarScrollEdgeInteraction = nil
            }
            return
        }

        let interaction: UIScrollEdgeElementContainerInteraction
        if let existingInteraction = navigationBarScrollEdgeInteraction as? UIScrollEdgeElementContainerInteraction {
            interaction = existingInteraction
        } else {
            interaction = UIScrollEdgeElementContainerInteraction()
            interaction.edge = .top
            navigationBarScrollEdgeInteraction = interaction
            navigationBar.addInteraction(interaction)
        }
        interaction.scrollView = scrollView
    }

    private func configureAudioBarScrollEdgeEffectIfNeeded() {
        guard #available(iOS 26.0, *) else { return }
        guard let audioView else { return }

        guard !audioBarHidden,
              let scrollView = contentScrollView()
        else {
            if let interaction = audioBarScrollEdgeInteraction {
                audioView.removeInteraction(interaction)
                audioBarScrollEdgeInteraction = nil
            }
            return
        }

        let interaction: UIScrollEdgeElementContainerInteraction
        if let existingInteraction = audioBarScrollEdgeInteraction as? UIScrollEdgeElementContainerInteraction {
            interaction = existingInteraction
        } else {
            interaction = UIScrollEdgeElementContainerInteraction()
            interaction.edge = .bottom
            audioBarScrollEdgeInteraction = interaction
            audioView.addInteraction(interaction)
        }
        interaction.scrollView = scrollView
    }

    private func contentScrollView() -> UIScrollView? {
        guard let contentViewController = contentView?.nearestViewController,
              let pageViewController = contentViewController.findViewController(ofType: UIPageViewController.self),
              let pageView = pageViewController.mostVisibleViewController?.viewIfLoaded
        else {
            return nil
        }

        return pageView.mostVisibleSubview(ofType: UIScrollView.self)
    }

    private func updateNavigationBarVisibility() {
        updateBarVisibility(navigationBar, hidden: navigationBarHidden)
    }

    private func updateAudioBarVisibility() {
        updateBarVisibility(audioView, hidden: audioBarHidden)
    }

    private func updateReadingModeBarVisibility() {
        updateBarVisibility(readingModeBarView, hidden: audioBarHidden)
    }

    private func pinReadingModeBar() {
        guard let readingModeBarView else {
            return
        }
        readingModeBarBottom?.isActive = false
        let barsTop = audioView?.topAnchor ?? safeAreaLayoutGuide.bottomAnchor
        readingModeBarBottom = readingModeBarView.bottomAnchor.constraint(equalTo: barsTop, constant: -Self.readingModeBarSpacing)
        readingModeBarBottom?.isActive = true
    }

    private var translationStripHidden: Bool {
        !translationStripShown || navigationBarHidden
    }

    private func updateTranslationStripVisibility() {
        updateBarVisibility(translationStripView, hidden: translationStripHidden)
    }

    @objc
    private func onSwipeDownFromTop(_ sender: UIPanGestureRecognizer) {
        if sender.state == .began {
            delegate?.onQuranViewSwipedDownFromTop(self)
        }
    }

    private func prepareBarForVisibilityTransition(
        _ view: UIView?,
        hidden: Bool,
        animated: Bool,
        stateChanged: Bool
    ) -> Bool {
        guard let view else { return false }
        guard animated, stateChanged else {
            view.layer.removeAllAnimations()
            updateBarVisibility(view, hidden: hidden)
            return false
        }

        if !hidden, view.isHidden {
            view.alpha = 0
        }
        view.isHidden = false
        view.isUserInteractionEnabled = !hidden
        return true
    }

    private func updateBarVisibility(_ view: UIView?, hidden: Bool) {
        view?.isHidden = hidden
        view?.isUserInteractionEnabled = !hidden
        view?.alpha = 1
    }

    private func setUp() {
        clipsToBounds = true
        tapGesture.addTarget(self, action: #selector(onViewTapped(_:)))
        tapGesture.delegate = self
        addGestureRecognizer(tapGesture)

        swipeDownFromTopGesture.addTarget(self, action: #selector(onSwipeDownFromTop(_:)))
        swipeDownFromTopGesture.delegate = self
        swipeDownFromTopGesture.cancelsTouchesInView = false
        addGestureRecognizer(swipeDownFromTopGesture)

        // navigation bar
        addAutoLayoutSubview(navigationBar)
        navigationBar.vc.horizontalEdges()
        safeAreaLayoutGuide.topAnchor.constraint(equalTo: navigationBar.topAnchor).isActive = true
        navigationBar.pushItem(navigationItem, animated: false)
        navigationBar.delegate = self
    }
}
