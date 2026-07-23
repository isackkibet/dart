import AVFoundation
import Flutter
import UIKit

private final class _PlayerContainerView: UIView {
    var playerLayer: AVPlayerLayer?

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }
}

class YohPalVideoView: NSObject, FlutterPlatformView {
    private let player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    private let containerView = _PlayerContainerView()

    override init() {
        super.init()
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        containerView.playerLayer = playerLayer
        containerView.layer.addSublayer(playerLayer)
    }

    func view() -> UIView { containerView }

    func load(url: String) {
        guard let videoUrl = URL(string: url) else { return }
        player.replaceCurrentItem(with: AVPlayerItem(url: videoUrl))
    }

    func play() { player.play() }

    func pause() { player.pause() }

    func seekTo(ms: Int) {
        let time = CMTime(seconds: Double(ms) / 1000.0, preferredTimescale: 600)
        player.seek(to: time)
    }

    func setMuted(_ muted: Bool) { player.isMuted = muted }

    func dispose() {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}
