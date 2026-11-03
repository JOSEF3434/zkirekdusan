package com.zikrekidusan.mobile

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import android.util.Rational
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val SECURITY_CHANNEL = "com.zikrekidusan.mobile/security"
    private val PIP_CHANNEL = "com.zikrekidusan.mobile/pip"

    private val ACTION_PIP_PLAY = "com.zikrekidusan.mobile.PIP_PLAY"
    private val ACTION_PIP_PAUSE = "com.zikrekidusan.mobile.PIP_PAUSE"

    private var pipChannel: MethodChannel? = null
    private var isPipEnabled: Boolean = false
    private var isVideoPlaying: Boolean = false
    private var aspectRatioNumerator: Int = 16
    private var aspectRatioDenominator: Int = 9
    private var pipReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Security Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecureMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Picture-in-Picture Channel
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isPipSupported" -> {
                    result.success(isPipSupported())
                }
                "enableAutoPip" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    val playing = call.argument<Boolean>("isPlaying") ?: false
                    val num = call.argument<Int>("numerator") ?: 16
                    val den = call.argument<Int>("denominator") ?: 9

                    isPipEnabled = enabled
                    isVideoPlaying = playing
                    aspectRatioNumerator = num.coerceIn(1, 239)
                    aspectRatioDenominator = den.coerceIn(1, 100)

                    updatePipParams()
                    result.success(true)
                }
                "disableAutoPip" -> {
                    isPipEnabled = false
                    isVideoPlaying = false
                    updatePipParams()
                    result.success(true)
                }
                "updatePlaybackState" -> {
                    val playing = call.argument<Boolean>("isPlaying") ?: false
                    if (isVideoPlaying != playing) {
                        isVideoPlaying = playing
                        updatePipParams()
                    }
                    result.success(true)
                }
                "enterPip" -> {
                    val num = call.argument<Int>("numerator") ?: aspectRatioNumerator
                    val den = call.argument<Int>("denominator") ?: aspectRatioDenominator
                    aspectRatioNumerator = num.coerceIn(1, 239)
                    aspectRatioDenominator = den.coerceIn(1, 100)
                    val entered = enterPipMode()
                    result.success(entered)
                }
                "isInPip" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        result.success(isInPictureInPictureMode)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        registerPipReceiver()
    }

    private fun isPipSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun buildPipParams(): PictureInPictureParams? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return null
        return try {
            val paramsBuilder = PictureInPictureParams.Builder()

            // Safe aspect ratio clamping (Android enforces ratio between 1:2.39 and 2.39:1)
            val clampedNum = aspectRatioNumerator.coerceIn(1, 239)
            val clampedDen = aspectRatioDenominator.coerceIn(1, 100)
            paramsBuilder.setAspectRatio(Rational(clampedNum, clampedDen))

            // Remote actions (Play / Pause in floating PiP window)
            val actions = ArrayList<RemoteAction>()
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }

            if (isVideoPlaying) {
                val pauseIntent = PendingIntent.getBroadcast(
                    this,
                    1,
                    Intent(ACTION_PIP_PAUSE).setPackage(packageName),
                    flags
                )
                actions.add(
                    RemoteAction(
                        Icon.createWithResource(this, android.R.drawable.ic_media_pause),
                        "Pause",
                        "Pause playback",
                        pauseIntent
                    )
                )
            } else {
                val playIntent = PendingIntent.getBroadcast(
                    this,
                    2,
                    Intent(ACTION_PIP_PLAY).setPackage(packageName),
                    flags
                )
                actions.add(
                    RemoteAction(
                        Icon.createWithResource(this, android.R.drawable.ic_media_play),
                        "Play",
                        "Resume playback",
                        playIntent
                    )
                )
            }
            paramsBuilder.setActions(actions)

            // Android 12+ (API 31+): Automatic entrance on gesture navigation
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                paramsBuilder.setAutoEnterEnabled(isPipEnabled && isVideoPlaying)
                paramsBuilder.setSeamlessResizeEnabled(true)
            }

            paramsBuilder.build()
        } catch (e: Exception) {
            null
        }
    }

    private fun updatePipParams() {
        if (!isPipSupported()) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val params = buildPipParams()
                if (params != null) {
                    setPictureInPictureParams(params)
                }
            } catch (e: Exception) {
                // Ignore parameter building failures on non-standard Android OEM roms
            }
        }
    }

    private fun enterPipMode(): Boolean {
        if (!isPipSupported()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                // Ensure FLAG_SECURE does not blank out PiP window while video is playing
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)

                val params = buildPipParams() ?: PictureInPictureParams.Builder().build()
                return enterPictureInPictureMode(params)
            } catch (e: Exception) {
                return false
            }
        }
        return false
    }

    // Triggered when user presses Home (including 3-button navigation circle) or switches apps
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isPipEnabled && isVideoPlaying && isPipSupported()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // For 3-button navigation or when OS gesture auto-enter did not run
                if (!isInPictureInPictureMode) {
                    enterPipMode()
                }
            }
        }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod(
            "onPictureInPictureModeChanged",
            mapOf("isInPip" to isInPictureInPictureMode)
        )
        if (!isInPictureInPictureMode) {
            updatePipParams()
        }
    }

    private fun registerPipReceiver() {
        if (pipReceiver != null) return
        pipReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    ACTION_PIP_PLAY -> {
                        isVideoPlaying = true
                        pipChannel?.invokeMethod("onPipAction", mapOf("action" to "play"))
                        updatePipParams()
                    }
                    ACTION_PIP_PAUSE -> {
                        isVideoPlaying = false
                        pipChannel?.invokeMethod("onPipAction", mapOf("action" to "pause"))
                        updatePipParams()
                    }
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(ACTION_PIP_PLAY)
            addAction(ACTION_PIP_PAUSE)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(pipReceiver, filter)
        }
    }

    override fun onDestroy() {
        pipReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Ignore if receiver was not registered or already unregistered
            }
            pipReceiver = null
        }
        super.onDestroy()
    }
}
