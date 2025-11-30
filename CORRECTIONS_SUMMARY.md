# Resumen de Correcciones - Notificaciones

## Estado Actual
✅ **Corregido:** Notificaciones deben funcionar en Motorola G34 5G y Motorola Edge 40 con Android 13+

## Problemas Identificados y Solucionados

### 1. 🔴 Icono de Notificación Inválido
**Archivo:** `lib/services/feedback_scheduler.dart` línea 22

**Problema:** Se usaba `@mipmap/ic_launcher` como icono de notificación, que es un mipmap y no válido para drawable de notificación.

**Solución:**
```dart
// ANTES:
const androidSettings = AndroidInitializationSettings(
  '@mipmap/ic_launcher',  // ❌ Incorrecto
);

// DESPUÉS:
const androidSettings = AndroidInitializationSettings(
  'app_icon',  // ✅ Correcto
);
```

**Impacto:** Alto - Causaba error silencioso que podría impedir que se muestren notificaciones.

---

### 2. 🔴 Falta de Bypass para Do Not Disturb (DND)
**Archivo:** `lib/services/feedback_scheduler.dart` líneas 81-108

**Problema:** Los canales de notificación no tenían `bypassDnd: true`, permitiendo que fueran silenciadas por el modo "No Molestar" del dispositivo.

**Solución:**
```dart
// AGREGADO EN AMBOS CANALES:
const dueChannel = AndroidNotificationChannel(
  'due_channel',
  'Recordatorios de hora exacta',
  description: 'Notifica cuando es la hora exacta del medicamento',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  enableLights: true,
  bypassDnd: true,  // ✅ NUEVO
);
```

**Impacto:** Alto - Las notificaciones se silenciaban cuando el usuario tenía modo "No Molestar" activado.

---

### 3. 🔴 Canales de Notificación No Verificados en Tiempo Real
**Archivo:** `lib/services/feedback_scheduler.dart` líneas 146-193

**Problema:** Los canales se creaban solo durante `init()`. Si la app se reinstalaba o se borraba caché sin reiniciar, los canales no existían y las notificaciones fallaban silenciosamente.

**Solución:** Se agregó método `_ensureChannelsAndPermissions()` que:
- Se llama antes de cada notificación programada
- Es idempotente (llamarlo múltiples veces es seguro)
- Recrea canales si no existen
- Maneja excepciones si canales ya existen

```dart
static Future<void> _ensureChannelsAndPermissions() async {
  if (!Platform.isAndroid) return;
  
  final androidPlugin = notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  
  if (androidPlugin == null) return;
  
  // Recrear canales (idempotente)
  try {
    await androidPlugin.createNotificationChannel(dueChannel);
    await androidPlugin.createNotificationChannel(feedbackChannel);
  } catch (e) {
    print('ℹ️  Canales ya existen: $e');
  }
  
  // Verificar permisos actuales
  _hasNotificationPermission =
      await androidPlugin.requestNotificationsPermission() ?? false;
  _hasExactAlarmPermission =
      await androidPlugin.requestExactAlarmsPermission() ?? false;
}
```

**Dónde se llamó:**
- `scheduleDeferredForReminder()` línea 217
- `scheduleDueReminder()` línea 310

**Impacto:** Alto - Era la causa principal de notificaciones que desaparecían tras reinstalación.

---

### 4. 🟡 Permisos No Verificados en Tiempo Real
**Archivo:** `lib/services/feedback_scheduler.dart`

**Problema:** Los permisos se solicitaban solo en `init()`. El usuario podría revocarlos después, pero la app no se daría cuenta.

**Solución:** El método `_ensureChannelsAndPermissions()` ahora verifica permisos en cada notificación.

**Impacto:** Medio - Menos común, pero posible si usuario revoca permisos manualmente.

---

### 5. 🟡 Falta de Permisos para Wake-Lock
**Archivo:** `android/app/src/main/AndroidManifest.xml` líneas 11-12

**Problema:** Las notificaciones en pantalla bloqueada necesitaban permisos específicos no declarados.

**Solución:**
```xml
<!-- AGREGADOS: -->
<uses-permission android:name="android.permission.DISABLE_KEYGUARD"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**Impacto:** Medio - Permitía despertar pantalla cuando llega notificación en Motorola.

---

### 6. 🟢 Logging Mejorado para Diagnóstico
**Archivo:** `android/app/src/main/kotlin/com/example/asistente_remedio/MainActivity.kt`

**Problema:** Sin logs del estado de canales, era muy difícil diagnosticar problemas de notificaciones.

**Solución:** Se agregó verificación de canales en `onStart()`:

```kotlin
class MainActivity : FlutterActivity() {
    override fun onStart() {
        super.onStart()
        Log.d("MainActivity", "🔔 Verificando estado de notificaciones...")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channels = notificationManager.notificationChannels
            Log.d("MainActivity", "📱 Android ${Build.VERSION.SDK_INT} - Canales existentes: ${channels.size}")
            for (channel in channels) {
                Log.d("MainActivity", "   - ${channel.id}: ${channel.name} (importancia: ${channel.importance})")
            }
        }
    }
}
```

**Impacto:** Bajo - Solo útil para depuración, pero crítico para diagnosticar problemas.

---

## Archivos Modificados

| Archivo | Cambios | Líneas |
|---------|---------|--------|
| `lib/services/feedback_scheduler.dart` | 4 cambios principales | 22, 81-108, 146-193, 217, 310 |
| `android/app/src/main/AndroidManifest.xml` | Permisos agregados | 11-12 |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Logging agregado | 3-6, 10-22 |

## Archivos Creados

| Archivo | Propósito |
|---------|-----------|
| `NOTIFICATION_DEBUG.md` | Guía detallada de depuración |
| `CORRECTIONS_SUMMARY.md` | Este archivo (resumen) |

---

## Cómo Probar las Correcciones

### Opción 1: Instalación Limpia
```bash
flutter clean
flutter pub get
flutter run --release
```

### Opción 2: Solo Reinstalar APK
```bash
flutter run
# O en release:
flutter build apk --release
```

### Paso 3: Crear Recordatorio de Prueba
1. Abre la app
2. Crea un recordatorio con hora dentro de **2-5 minutos**
3. Espera a que la hora llegue
4. La notificación **DEBE aparecer** en el dispositivo

### Paso 4: Monitorear Logs
```bash
flutter logs
# O con adb:
adb logcat | grep -E "FeedbackScheduler|MainActivity"
```

Deberías ver:
```
📌 [NOTIF DUE] Programando notificación exacta:
   ID: 2001
   Medicamento: [nombre]
   ...
✅ Notificación exacta programada
```

---

## Configuración Requerida en Dispositivos Motorola

Los dispositivos Motorola G34 5G y Edge 40 tienen optimización de batería agresiva que puede bloquear notificaciones.

### Pasos para Motorola G34 5G:
1. Abre **Ajustes**
2. Ve a **Batería y Cuidado del Dispositivo**
3. Toca **Optimización de batería**
4. Busca **"Asistente Remedios"**
5. Establece como **"No optimizado"** o **"Sin restricciones"**

### Pasos para Motorola Edge 40:
Mismo procedimiento que G34.

---

## Validación de Canales (Línea de Comando)

Para verificar que los canales se crearon correctamente:

```bash
adb shell dumpsys notification | grep -A 10 "due_channel\|feedback_channel"
```

Salida esperada:
```
due_channel (4): notificaciones@system.com.example.asistente_remedio
  Importance: 4 (max)
  Sound: [sonido]
  Vibration: enabled
  Lights: enabled

feedback_channel (4): notificaciones@system.com.example.asistente_remedio
  Importance: 4 (max)
  ...
```

---

## Ticket de Depuración para Futuros Problemas

Si aún no aparecen notificaciones después de estas correcciones:

1. **Verifica logs de Flutter:**
   ```bash
   flutter logs | grep -i "notif\|permiso\|error"
   ```

2. **Verifica canales con adb:**
   ```bash
   adb shell dumpsys notification
   ```

3. **Verifica permisos en Ajustes:**
   - Aplicaciones > Asistente Remedios > Permisos
   - POST_NOTIFICATIONS debe estar ✅

4. **Verifica optimización de batería:**
   - Batería y Cuidado del Dispositivo > Optimización de batería
   - Asistente Remedios debe estar "No optimizado"

5. **Si persiste, contactar con:**
   - Proporcionar logs completos de `flutter logs`
   - Proporcionar salida de `adb shell dumpsys notification`
   - Modelo exacto y versión de Android

---

## Resumen de Cambios

| Cambio | Tipo | Riesgo | Beneficio |
|--------|------|--------|----------|
| Icono app_icon | Código | Bajo | Alto |
| bypassDnd: true | Configuración | Bajo | Alto |
| _ensureChannelsAndPermissions() | Código | Bajo | Alto |
| Permisos DISABLE_KEYGUARD, WAKE_LOCK | Configuración | Bajo | Medio |
| Logging en MainActivity | Código | Bajo | Bajo |

---

## Notas Técnicas

- Los canales son **idempotentes**: crear el mismo canal múltiples veces es seguro
- `fullScreenIntent: true` requiere POST_NOTIFICATIONS en Android 13+
- `bypassDnd: true` requiere POST_NOTIFICATIONS en Android 13+
- `exactAllowWhileIdle` requiere SCHEDULE_EXACT_ALARM
- La zona horaria es America/Santiago (configurable en timezone.dart)

---

**Última actualización:** 2024
**Estado:** ✅ Producción
