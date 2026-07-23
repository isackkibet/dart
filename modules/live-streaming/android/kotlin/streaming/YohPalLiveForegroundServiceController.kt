package com.example.yohpal_live_v2

import android.content.Context
import android.content.Intent
import android.os.Build

object YohPalLiveForegroundServiceController {

    fun start(context: Context) {
        val intent = Intent(context, YohPalLiveForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun stop(context: Context) {
        val intent = Intent(context, YohPalLiveForegroundService::class.java)
        context.stopService(intent)
    }
}
