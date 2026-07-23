package com.main.yohpal_app

import androidx.media3.common.util.UnstableApi
import com.yohpal.live.video.YohPalVideoPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

@UnstableApi
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(YohPalVideoPlugin())
    }
}
