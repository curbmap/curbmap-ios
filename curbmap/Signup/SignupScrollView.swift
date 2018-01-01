//
//  SignupScrollView.swift
//  curbmap
//
//  Created by Eli Selkin on 12/31/17.
//  Copyright © 2017 Eli Selkin. All rights reserved.
//

import UIKit

class SignupScrollView: UIScrollView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return subviews.contains(where: {
            !$0.isHidden && $0.point(inside: point, with: event)
        })
    }
}
