import Flutter
import UIKit

class YohPalVideoPlugin: NSObject, FlutterPlugin {
    private let videoView = YohPalVideoView()

    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = YohPalVideoPlugin()
        registrar.register(
            YohPalVideoViewFactory(videoView: instance.videoView),
            withId: "yohpal.video/view"
        )
        let channel = FlutterMethodChannel(
            name: "yohpal.video/native",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]
        switch call.method {
        case "load":
            if let url = args?["url"] as? String { videoView.load(url: url) }
            result(nil)
        case "play":
            videoView.play()
            result(nil)
        case "pause":
            videoView.pause()
            result(nil)
        case "seekTo":
            videoView.seekTo(ms: args?["ms"] as? Int ?? 0)
            result(nil)
        case "setMuted":
            videoView.setMuted(args?["muted"] as? Bool ?? false)
            result(nil)
        case "dispose":
            videoView.dispose()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
