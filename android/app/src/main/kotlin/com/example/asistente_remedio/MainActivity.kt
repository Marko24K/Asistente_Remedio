package com.example.asistente_remedio

import android.app.NotificationManager
import android.content.Context
import android.media.MediaPlayer
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.asistente_remedio/boot"
    private val AUDIO_CHANNEL = "com.example.asistente_remedio/audio"
    private var mediaPlayer: MediaPlayer? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // ========== BOOT CHANNEL ==========
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "rescheduleNotifications" -> {
                    Log.d("MainActivity", "📞 Dart solicitó reschedule de notificaciones")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        // ========== AUDIO CHANNEL ==========
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playSound" -> {
                    val soundName = call.argument<String>("soundName")
                    if (soundName != null) {
                        playSound(soundName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "soundName es requerido", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        
        // ========== DEVICE OPTIMIZATION CHANNEL ==========
        DeviceOptimizationService.setupMethodChannel(this, flutterEngine)
    }
    
    private fun playSound(soundName: String) {
        try {
            Log.d("MainActivity", "🔊 Reproduciendo sonido: $soundName")
            
            // Obtener el ID del recurso raw
            val resourceId = resources.getIdentifier(
                soundName.replace(".mp3", ""),
                "raw",
                packageName
            )
            
            if (resourceId == 0) {
                Log.e("MainActivity", "❌ Sonido no encontrado: $soundName")
                return
            }
            
            // Detener reproducción anterior si existe
            mediaPlayer?.release()
            
            // Crear nuevo MediaPlayer
            mediaPlayer = MediaPlayer.create(this, resourceId)
            mediaPlayer?.setOnCompletionListener {
                Log.d("MainActivity", "✅ Sonido completado: $soundName")
                it.release()
                mediaPlayer = null
            }
            
            // Reproducir
            mediaPlayer?.start()
            Log.d("MainActivity", "▶️  Sonido iniciado: $soundName")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Error reproduciendo sonido: ${e.message}")
        }
    }
    
    override fun onStart() {
        super.onStart()
        Log.d("MainActivity", "🔔 onStart() - Inicializando...")
        
        // Verificar si fue lanzada por BOOT_COMPLETED
        val bootReschedule = intent?.getBooleanExtra("boot_reschedule", false) ?: false
        if (bootReschedule) {
            Log.d("MainActivity", "🚀 Reschedule post-boot detectado")
        }
        
        // Mostrar canales de notificación
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channels = notificationManager.notificationChannels
            Log.d("MainActivity", "📱 Android ${Build.VERSION.SDK_INT} - ${channels.size} canales")
            for (channel in channels) {
                Log.d(
                    "MainActivity",
                    "   ${channel.id}: ${channel.name} (importancia: ${channel.importance})"
                )
            }
        }
        
        // Mostrar info del dispositivo
        Log.d("MainActivity", "🖥️  Dispositivo: ${Build.MANUFACTURER} ${Build.MODEL}")
        Log.d("MainActivity", "📍 Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        mediaPlayer?.release()
        mediaPlayer = null
    }
}
