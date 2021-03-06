//
//  AppDelegate.swift
//  APoD
//
//  Created by 宋 奎熹 on 2018/1/6.
//  Copyright © 2018年 宋 奎熹. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
         
        Bugly.start(withAppId: APOD_BUGLY_ID)
        
        if !kUserDefaults.bool(forKey: "first_apod") {
            kUserDefaults.set(videoRatioArray[0].ratio, forKey: "video_ratio")
            kUserDefaults.set(true, forKey: "first_apod")
            kUserDefaults.synchronize()
        }
        
        window?.backgroundColor = .apod
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.absoluteString.contains("widgetopen") {
            let tabVC: UITabBarController = self.window!.rootViewController as! UITabBarController
            tabVC.selectedIndex = 0
            let navVC: APODNavigationController = tabVC.viewControllers![0] as! APODNavigationController
            let calendarVC: APODInfoTableViewController = navVC.viewControllers[0] as! APODInfoTableViewController
            calendarVC.currentDate = apodDateFormatter.date(from: url.absoluteString.substring("apodscheme://widgetopen?date=".count))!
        }
        return true
    }

}

