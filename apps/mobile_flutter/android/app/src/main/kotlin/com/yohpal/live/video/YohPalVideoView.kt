package com.yohpal.live.video

import android.content.Context
import android.view.View
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import io.flutter.plugin.platform.PlatformView

@UnstableApi
class YohPalVideoView(context: Context) : PlatformView {
    private val playerView = PlayerView(context)
    private val player = ExoPlayer.Builder(context).build()

    init {
        playerView.player = player
        playerView.useController = false
    }

    fun load(url: String) {
        val mediaItem = MediaItem.fromUri(url)
        player.setMediaItem(mediaItem)
        player.prepare()
    }

    fun play() { player.play() }

    fun pause() { player.pause() }

    fun seekTo(ms: Long) { player.seekTo(ms) }

    fun setMuted(muted: Boolean) { player.volume = if (muted) 0f else 1f }

    override fun getView(): View = playerView

    override fun dispose() { player.release() }
}
