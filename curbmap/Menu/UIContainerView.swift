//
//  UIContainerView.swift
//  curbmap
//
//  Created by Eli Selkin on 12/31/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit

class UIContainerView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.contains(where: {
            !$0.isHidden && $0.point(inside: point, with: event)
        })
    }
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let view = gestureRecognizer.view, view.isKind(of: UIControl.self) else {
            return true
        }
        return false
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
}

