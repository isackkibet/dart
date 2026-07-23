import Flutter
import AVKit
import AVFoundation

final class YohPalPiPBridge: NSObject, AVPictureInPictureControllerDelegate {
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  private var pipController: AVPictureInPictureController?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "yohpal.live/ios_pip",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "isPiPSupported":
        result(AVPictureInPictureController.isPictureInPictureSupported())
      case "preparePiP":
        guard
          let args = call.arguments as? [String: Any],
          let videoUrl = args["videoUrl"] as? String
        else {
          result(false)
          return
        }
        result(self.preparePiP(videoUrl: videoUrl))
      case "startPiP":
        result(self.startPiP())
      case "stopPiP":
        result(self.stopPiP())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func preparePiP(videoUrl: String) -> Bool {
    guard let url = URL(string: videoUrl) else {
      return false
    }
    let player = AVPlayer(url: url)
    let layer = AVPlayerLayer(player: player)
    self.player = player
    self.playerLayer = layer
    if AVPictureInPictureController.isPictureInPictureSupported() {
      self.pipController = AVPictureInPictureController(playerLayer: layer)
      self.pipController?.delegate = self
      return true
    }
    return false
  }

  private func startPiP() -> Bool {
    guard let controller = pipController else {
      return false
    }
    player?.play()
    if controller.isPictureInPicturePossible {
      controller.startPictureInPicture()
      return true
    }
    return false
  }

  private func stopPiP() -> Bool {
    guard let controller = pipController else {
      return false
    }
    if controller.isPictureInPictureActive {
      controller.stopPictureInPicture()
      return true
    }
    return false
  }
}
