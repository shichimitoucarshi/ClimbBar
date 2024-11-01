//
//  ClimbBar.swift
//  ClimbBar
//
//  Created by Shichimitoucarashi on 5/8/19.
//  Copyright © 2019 Shichimitoucarashi. All rights reserved.
//

import UIKit.UIGestureRecognizer

// swiftlint:disable all
public class ClimbBar: NSObject {
    public var observer: ((State) -> Void)?
    public var isReachable: Bool = false

    let defaultContentOffset: CGPoint
    let defaultInset: UIEdgeInsets
    let scrollable: UIScrollView
    var configuration: Configuration
    var swipeStartPosition: CGFloat = 0
    var previousState: CGFloat!
    var climbBarObservable: ClimbBarObservable

    public struct State {
        var configuration: Configuration
        var begin: CGFloat
        var offset: CGPoint
        var origin: CGPoint

        init(conf: Configuration,
             begin: CGFloat,
             offset: CGPoint,
             origin: CGPoint)
        {
            configuration = conf
            self.begin = begin
            self.offset = offset
            self.origin = origin
        }
    }

    public init(configurations: Configuration,
                scrollable: UIScrollView)
    {
        configuration = configurations
        self.scrollable = scrollable
        previousState = configuration.compact
        defaultContentOffset = CGPoint(x: 0, y: -configuration.normal)
        defaultInset = UIEdgeInsets(top: configuration.normal,
                                    left: scrollable.contentInset.left,
                                    bottom: scrollable.contentInset.bottom,
                                    right: scrollable.contentInset.right)

        climbBarObservable = ClimbBarObservable(key: #keyPath(UIScrollView.contentOffset), object: self.scrollable)

        super.init()

        climbBarObservable.observer = { [weak self] _ in
            guard let self = self else { return }
            let state = State(conf: self.configuration,
                              begin: self.swipeStartPosition,
                              offset: self.scrollable.contentOffset,
                              origin: self.scrollable.frame.origin)
            guard !self.isReachable else { return }
            self.observer?(state)
            self.previousState = state.originY
        }
        setup(configurations)
    }

    private func setup(_: Configuration) {
        scrollable.panGestureRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
        if scrollable.contentInsetAdjustmentBehavior == .never {
            setScrollable(contentInset: defaultInset,
                          contentOffset: defaultContentOffset)
        }
    }

    private func setScrollable(contentInset: UIEdgeInsets,
                               contentOffset: CGPoint)
    {
        scrollable.contentInset = contentInset
        scrollable.contentOffset = contentOffset
    }

    public func emit(_ handler: @escaping (State) -> Void) {
        observer = handler
    }

    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began:
            isReachable = false
            swipeStartPosition = scrollable.contentOffset.y
            configuration.currentStatus = previousState
        case .ended:
            /*
             * If the start and stop times are less than or equal to zero,
             * the movement is stopped.
             */
            if swipeStartPosition < 0,
               scrollable.contentOffset.y < configuration.lower
            {
                isReachable = true
            }
        case .possible, .changed, .cancelled, .failed:
            break
        @unknown default:
            break
        }
    }
}

// swiftlint:enable all
