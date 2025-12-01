package com.example.asistente_remedio

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object DeviceOptimizationService {
    private const val CHANNEL = "com.example.asistente_remedio/device"

    fun setupMethodChannel(context: Context, flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestIgnoreBatteryOptimization" -> {
                    val success = requestIgnoreBatteryOptimization(context)
                    result.success(success)
                }
                "getDeviceInfo" -> {
                    val info = getDeviceInfo()
                    result.success(info)
                }
                "requestExactAlarmPermission" -> {
                    val success = requestExactAlarmPermission(context)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ========================================================
    // SOLICITAR EXCLUSIÓN DE OPTIMIZACIÓN DE BATERÍA
    // ========================================================
    private fun requestIgnoreBatteryOptimization(context: Context): Boolean {
        return try {
            Log.d("DeviceOptimization", "🔋 Solicitando exclusión de batería...")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+: REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val packageName = context.packageName

                if (powerManager.isIgnoringBatteryOptimizations(packageName)) {
                    Log.d("DeviceOptimization", "✅ Ya excluida de optimización")
                    return true
                }

                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }

                context.startActivity(intent)
                Log.d("DeviceOptimization", "✅ Intent lanzado (usuario debe confirmar)")
                true
            } else {
                Log.d("DeviceOptimization", "⚠️  Android < 12, ignorando")
                true
            }
        } catch (e: Exception) {
            Log.e("DeviceOptimization", "❌ Error: ${e.message}")
            false
        }
    }

    // ========================================================
    // OBTENER INFORMACIÓN DEL DISPOSITIVO
    // ========================================================
    private fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "manufacturer" to (Build.MANUFACTURER ?: "Unknown"),
            "model" to (Build.MODEL ?: "Unknown"),
            "android_version" to Build.VERSION.RELEASE,
            "sdk_int" to Build.VERSION.SDK_INT.toString(),
            "device" to (Build.DEVICE ?: "Unknown")
        ).also {
            Log.d("DeviceOptimization", "📱 Info: $it")
        }
    }

    // ========================================================
    // SOLICITAR PERMISO SCHEDULE_EXACT_ALARM EXPLÍCITAMENTE
    // ========================================================
    private fun requestExactAlarmPermission(context: Context): Boolean {
        return try {
            Log.d("DeviceOptimization", "⏰ Solicitando permiso SCHEDULE_EXACT_ALARM...")

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Android 12+: Abrir settings directamente
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }

                context.startActivity(intent)
                Log.d("DeviceOptimization", "✅ Intent de exacto lanzado")
                true
            } else {
                Log.d("DeviceOptimization", "⚠️  Android < 12")
                true
            }
        } catch (e: Exception) {
            Log.e("DeviceOptimization", "❌ Error: ${e.message}")
            false
        }
    }
}
