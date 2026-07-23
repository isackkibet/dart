package com.yohpal.live.video

import androidx.media3.common.util.UnstableApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

@UnstableApi
class YohPalVideoPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel
    private var videoView: YohPalVideoView? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        videoView = YohPalVideoView(binding.applicationContext)
        binding.platformViewRegistry.registerViewFactory(
            "yohpal.video/view",
            YohPalVideoViewFactory { videoView!! }
        )
        channel = MethodChannel(binding.binaryMessenger, "yohpal.video/native")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "load" -> {
                    val url = call.argument<String>("url")!!
                    videoView?.load(url)
                    result.success(null)
                }
                "play" -> {
                    videoView?.play()
                    result.success(null)
                }
                "pause" -> {
                    videoView?.pause()
                    result.success(null)
                }
                "seekTo" -> {
                    val ms = call.argument<Int>("ms") ?: 0
                    videoView?.seekTo(ms.toLong())
                    result.success(null)
                }
                "setMuted" -> {
                    val muted = call.argument<Boolean>("muted") ?: false
                    videoView?.setMuted(muted)
                    result.success(null)
                }
                "dispose" -> {
                    videoView?.dispose()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        videoView?.dispose()
        videoView = null
    }
}
