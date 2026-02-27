import Flutter
import UIKit
import Firebase
import FirebaseMessaging
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate,MessagingDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
     
      FirebaseApp.configure()
      Messaging.messaging().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
}
