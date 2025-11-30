package com.example.asistente_remedio

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Dispositivo reiniciado, rescheduleando notificaciones...")
            
            // Aquí se podría enviar un método al lado Dart para reschedule las notificaciones
            // Por ahora solo log
            Log.d("BootReceiver", "Se necesitará reschedule de notificaciones")
        }
    }
}
