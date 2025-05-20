import UIKit
import Flutter
import FBSDKCoreKit
import AVFoundation
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configuración avanzada de AVAudioSession
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay, .mixWithOthers]
      )
      try session.setActive(true, options: .notifyOthersOnDeactivation)
      try session.setPreferredIOBufferDuration(0.005)
    } catch {
      print("Error al configurar AVAudioSession: \(error.localizedDescription)")
    }

    // Inicializar Facebook SDK
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    // Registrar plugins de Flutter
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Manejar URLs de Google Sign-In
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }

    // Manejar URLs de Facebook Login
    if ApplicationDelegate.shared.application(app, open: url, options: options) {
      return true
    }

    return super.application(app, open: url, options: options)
  }
  
  // Configuración adicional para manejo de audio en segundo plano
  override func applicationWillResignActive(_ application: UIApplication) {
    do {
      try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      print("Error al desactivar AVAudioSession: \(error.localizedDescription)")
    }
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Error al reactivar AVAudioSession: \(error.localizedDescription)")
    }
  }
}