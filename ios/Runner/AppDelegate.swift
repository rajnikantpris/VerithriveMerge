import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import FirebaseCore
import GoogleMaps
import FBSDKCoreKit

@main
@objc class AppDelegate: FlutterAppDelegate,MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     
//      GMSServices.provideAPIKey("AIzaSyDjdom-8K5VyqYV_zFUtPX_Zabk3r-C6XQ")//development
        GMSServices.provideAPIKey("AIzaSyAt1ojfod_QD5VxSBOnp3s3OpbVuVlFIOY")//production
      
      
      FirebaseApp.configure()
      Messaging.messaging().delegate = self
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    ApplicationDelegate.shared.application(
      app,
      open: url,
      sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
      annotation: options[UIApplication.OpenURLOptionsKey.annotation]
    )
    return super.application(app, open: url, options: options)
  }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Xcode FCM Token -> \(fcmToken ?? "nil")")
    }
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Xcode didRegisterForRemoteNotificationsWithDeviceToken")
 
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Xcode didReceiveRemoteNotification")
 
        Messaging.messaging().appDidReceiveMessage(userInfo)
    }
    // 👇 THIS IS IMPORTANT
      override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
          @escaping (UNNotificationPresentationOptions) -> Void
      ) {
          print("🔥 Foreground Notification Received")
  
  let userInfo = notification.request.content.userInfo
  print("📩 Notification Data: \(userInfo)")


        completionHandler([.alert, .badge, .sound])
      }
}
