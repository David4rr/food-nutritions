import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FoodNutritionsOcrPlugin") else {
      return
    }
    let channel = FlutterMethodChannel(name: "com.food_nutritions.ocr/recognize", binaryMessenger: registrar.messenger())

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "recognizeText" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "imagePath required", details: nil))
          return
        }

        DispatchQueue.global(qos: .userInitiated).async {
          guard let image = UIImage(contentsOfFile: imagePath),
                let cgImage = image.cgImage else {
            DispatchQueue.main.async {
              result("")
            }
            return
          }

          let orientation = CGImagePropertyOrientation(image.imageOrientation)
          let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
          let request = VNRecognizeTextRequest { (req, _) in
            guard let observations = req.results as? [VNRecognizedTextObservation] else {
              DispatchQueue.main.async { result("") }
              return
            }
            let lines = observations.compactMap { $0.topCandidates(1).first?.string }
            let fullText = lines.joined(separator: "\n")
            DispatchQueue.main.async {
              result(fullText)
            }
          }
          request.recognitionLevel = .accurate
          request.usesLanguageCorrection = false
          request.recognitionLanguages = ["id-ID", "en-US"]

          do {
            try requestHandler.perform([request])
          } catch {
            DispatchQueue.main.async {
              result("")
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

extension CGImagePropertyOrientation {
  init(_ uiOrientation: UIImage.Orientation) {
    switch uiOrientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
