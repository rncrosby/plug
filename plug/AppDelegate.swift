//
//  AppDelegate.swift
//  plug
//
//  Created by Robert Crosby on 5/23/20.
//  Copyright © 2020 Robert Crosby. All rights reserved.
//

import UIKit
import Firebase
import Stripe
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var root:RootViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Stripe.setDefaultPublishableKey("pk_test_R6tniSYZ4xhfo5WpKSHMhtjW")
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.applicationIconBadgeNumber = 0
        // Override point for customization after application launch.
        root = RootViewController.init()
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("NOTIFICATION RECIEVED NOT CLOSED: \(response.notification.request.content.userInfo)")
        if  let kind = response.notification.request.content.userInfo["kind"] as? String,
            let identifier = response.notification.request.content.userInfo["id"] as? String,
            let body = response.notification.request.content.userInfo["aps"] as? [String:Any] {
            print("kind: \(kind), id: \(identifier)")
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

            if var topController = keyWindow?.rootViewController {
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                if kind == "message" {
                    Firestore.firestore().collection("offers").document(identifier).getDocument { (snapshot, error) in
                        if let id = snapshot?.documentID,
                            let data = snapshot?.data() {
                            var offer = Offer.init(id, data)
                            self.root!.present(OfferViewController.init(offer: &offer), animated: true, completion: nil)
                        }
                    }
                }
                if kind == "item" {
                    Firestore.firestore().collection("items").document(identifier).getDocument { (snapshot, error) in
                        if let id = snapshot?.documentID,
                            let data = snapshot?.data() {
                            var item = Item.init(fromQuery: data, id)
                            let nav = UINavigationController.init(rootViewController: ItemViewController.init(item: &item))
                            nav.navigationBar.prefersLargeTitles = false
                            self.root!.present(nav, animated: true)
                        }
                    }
                }
            // topController should now be your topmost view controller
            }
        }

    }
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate : MessagingDelegate {
    
  // [START refresh_token]
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    if let uid = Auth.auth().currentUser?.uid {
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        print("Firebase Token: \(fcmToken)")
        if needToUpdateToken(fcmToken) {
            updateNotificationToken(uid, fcmToken) { (result) in
                if result {
                    print("success")
                } else {
                    print("error")
                }
            }
        } else {
            print("Doesn't need to update token")
        }
        
        
    }
    
  }

}

func needToUpdateToken(_ new: String) -> Bool {
    if let current = UserDefaults.standard.string(forKey: "token") {
        return !(current == new)
    }
    return true
}

func updateNotificationToken(_ uid: String, _ token: String, _ complete: @escaping (Bool) -> ()) {
    UserDefaults.standard.set(token, forKey: "token")
    Firestore.firestore().collection("users").document(uid).updateData([
        "token" : token
    ]) { (error) in
        if let error = error {
            print(error.localizedDescription)
            complete(false)
            return
        }
        complete(true)
    }
}

func clearToken(_ uid: String, _ complete: @escaping (Bool) -> ()) {
    UserDefaults.standard.removeObject(forKey: "token")
    Firestore.firestore().collection("users").document(uid).updateData([
        "token" : FieldValue.delete()
    ]) { (error) in
        if let error = error {
            print(error.localizedDescription)
            complete(false)
            return
        }
        complete(true)
    }
}
