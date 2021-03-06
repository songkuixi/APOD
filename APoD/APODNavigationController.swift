//
//  APODNavigationController.swift
//  APoD
//
//  Created by 宋 奎熹 on 2018/1/6.
//  Copyright © 2018年 宋 奎熹. All rights reserved.
//

import UIKit

class APODNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    
    override var childForStatusBarStyle: UIViewController? {
        return visibleViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.interactivePopGestureRecognizer?.delegate = self
        self.navigationBar.prefersLargeTitles = true
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.viewControllers.count >= 1 {
            let button = UIButton(type: .custom)
            button.bounds = CGRect(x: 0, y: 0, width: 100, height: 21)
            button.setImage(#imageLiteral(resourceName: "nav_back"), for: .normal)
            button.setImage(#imageLiteral(resourceName: "nav_back"), for: .highlighted)
            button.contentHorizontalAlignment = .left
            button.contentEdgeInsets = .zero
            button.tintColor = .apodReversed
            button.addTarget(self, action: #selector(back), for: .touchUpInside)
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        }
        super.pushViewController(viewController, animated: animated)
    }
    
    @objc func back() {
        self.popViewController(animated: true)
    }
    
}

