package com.aestheticcamera.aesthetic_camera

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "aesthetic_camera/flashlight"
    private var cameraId: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "hasTorch" -> result.success(torchCameraId() != null)
                        "supportsIntensity" -> result.success(maxTorchStrength() > 1)
                        "setEnabled" -> {
                            val enabled = call.argument<Boolean>("enabled") == true
                            setTorch(enabled)
                            result.success(null)
                        }
                        "setIntensity" -> {
                            val intensity = call.argument<Double>("intensity") ?: 0.8
                            setTorchStrength(intensity)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("FLASHLIGHT", error.message, null)
                }
            }
    }

    private fun cameraManager(): CameraManager {
        return getSystemService(Context.CAMERA_SERVICE) as CameraManager
    }

    private fun torchCameraId(): String? {
        cameraId?.let { return it }
        val manager = cameraManager()
        val id = manager.cameraIdList.firstOrNull { camera ->
            manager.getCameraCharacteristics(camera)
                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        }
        cameraId = id
        return id
    }

    private fun maxTorchStrength(): Int {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return 1
        }
        val id = torchCameraId() ?: return 1
        return cameraManager()
            .getCameraCharacteristics(id)
            .get(CameraCharacteristics.FLASH_INFO_STRENGTH_MAXIMUM_LEVEL) ?: 1
    }

    private fun setTorch(enabled: Boolean) {
        val id = torchCameraId() ?: throw IllegalStateException("No flashlight on this device.")
        if (!enabled) {
            cameraManager().setTorchMode(id, false)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && maxTorchStrength() > 1) {
            setTorchStrength(0.8)
        } else {
            cameraManager().setTorchMode(id, true)
        }
    }

    private fun setTorchStrength(intensity: Double) {
        val id = torchCameraId() ?: throw IllegalStateException("No flashlight on this device.")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && maxTorchStrength() > 1) {
            val max = maxTorchStrength()
            val level = (intensity.coerceIn(0.05, 1.0) * max).toInt().coerceIn(1, max)
            cameraManager().setTorchStrengthLevel(id, level)
        } else {
            cameraManager().setTorchMode(id, intensity > 0.04)
        }
    }
}
