import Flutter
import UIKit

class YohPalVideoViewFactory: NSObject, FlutterPlatformViewFactory {
    private let videoView: YohPalVideoView

    init(videoView: YohPalVideoView) {
        self.videoView = videoView
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return videoView
    }
}
