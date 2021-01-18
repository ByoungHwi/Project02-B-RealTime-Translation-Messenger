//
//  ChatCollectionView.swift
//  PapagoTalk
//
//  Created by Byoung-Hwi Yoon on 2020/12/12.
//

import UIKit

final class ChatCollectionView: UICollectionView {
    
    func scrollToLast() {
        layoutIfNeeded()
        let newY = contentSize.height - bounds.height
        setContentOffset(CGPoint(x: .zero, y: newY < .zero ? .zero : newY), animated: false)
    }
    
    func keyboardWillShow(keyboardHeight: CGFloat) {
        guard let superview = superview else {
            return
        }
        var offset = contentOffset
        var yOffSet = keyboardHeight - superview.safeAreaInsets.bottom
        var maxYOffSet = contentSize.height - bounds.height
        if maxYOffSet < .zero {
            maxYOffSet = .zero
        }
        yOffSet = yOffSet > maxYOffSet ? maxYOffSet : yOffSet
        offset.y += yOffSet
        setContentOffset(offset, animated: false)
        layoutIfNeeded()
    }
    
    func keyboardWillHide(keyboardHeight: CGFloat) {
        guard let superview = superview else {
            return
        }
        var offset = contentOffset
        let yOffSet = keyboardHeight - superview.safeAreaInsets.bottom
        offset.y -= yOffSet
        offset.y = offset.y < .zero ? .zero : offset.y
        setContentOffset(offset, animated: false)
        layoutIfNeeded()
    }
}
