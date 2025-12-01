# 🔧 GUÍA DE DEBUGGING - NOTIFICACIONES ANDROID 15 (MOTOROLA)

## 📋 PROBLEMAS RESUELTOS

Este proyecto ha sido actualizado para resolver **8 problemas críticos** que causaban que las notificaciones no aparecieran o llegaran tarde en Android 15 (especialmente Motorola):

### 1. ✅ **Doze Mode no configurado**
- **Problema**: Android 15 entra agresivamente en Doze Mode cancelando notificaciones exactas
- **Solución**: Agregado `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` en AndroidManifest.xml y llamada explícita en init

### 2. ✅ **Permisos POST_NOTIFICATIONS sin sincronización**
- **Problema**: Se intentaba programar notificaciones sin verificar que el permiso fue otorgado
- **Solución**: Verificación explícita y reintentos en `_ensureChannelsAndPermissions()`

### 3. ✅ **Permiso exacto no verificado antes de programar**
- **Problema**: Variable `_hasExactAlarmPermission` podía ser falsa en tiempo de programación
- **Solución**: Llamada a `_ensureChannelsAndPermissions()` antes de cada programación de notificación

### 4. ✅ **BootReceiver no reschedule notificaciones**
- **Problema**: Al reiniciar dispositivo, todas las notificaciones programadas se perdían
- **Solución**: BootReceiver ahora lanza MainActivity, que dispara el reschedule desde Dart

### 5. ✅ **Sin FOREGROUND_SERVICE para notificaciones diferidas**
- **Problema**: Notificaciones diferidas (20-60 min) se cancelaban en Doze Mode
- **Solución**: Permisos agregados, flutter_local_notifications maneja esto internamente

### 6. ✅ **Motorola requiere request explícito de SCHEDULE_EXACT_ALARM**
- **Problema**: Algunos Motorola no reconocen el permiso unless explicitly requested
- **Solución**: Nueva clase `DeviceOptimizationHelper` con `applyMotorolaWorkaround()`

### 7. ✅ **App en lista de batería restringida**
- **Problema**: Si el usuario restringe manualmente la app, NO habrá notificaciones
- **Solución**: Intent automático para solicitar exclusión de optimización

### 8. ✅ **Logs insuficientes para debugging**
- **Problema**: Difícil de debuggear dónde fallaba exactamente
- **Solución**: Logging exhaustivo en cada paso + `NotificationDebugger`

---

## 🧪 PASOS PARA DEBUGGING EN ANDROID 15 MOTOROLA

### 1. **Compilar en Release Mode**
```bash
flutter clean
flutter pub get
flutter run --release
```

### 2. **Verificar Logcat**
```bash
# Terminal 1: Ver todos los logs
adb logcat | grep -E "FeedbackScheduler|MainActivity|BootReceiver|DeviceOptimization"

# Terminal 2: Ver solo errores
adb logcat *:E | grep -E "asistente_remedio|FeedbackScheduler"
```

### 3. **Verificar Permisos en el Dispositivo**
```bash
# Ver permisos otorgados
adb shell pm dump com.example.asistente_remedio | grep -A 20 "install permissions"

# Verificar si está en lista de batería restringida
adb shell cmd deviceidle get restricted
```

### 4. **Solicitar Exclusión de Batería Manualmente**
Si el usuario lo niega automáticamente:
1. Ir a: **Configuración → Batería → Optimización de batería (o Uso de batería)**
2. Buscar "Asistente Remedio"
3. Cambiar a "No optimizar"

### 5. **Verificar Canales de Notificación**
```bash
adb shell cmd notification list_channels com.example.asistente_remedio
```

Deberías ver:
```
Channel: due_channel (Recordatorios de hora exacta)
  - Importance: 4 (MAX)
  - Sound: default
  - Vibration: true

Channel: feedback_channel (Recordatorios diferidos)
  - Importance: 4 (MAX)
  - Sound: default
  - Vibration: true
```

### 6. **Activar Reporte Completo de Notificaciones**
En `patient_home_screen.dart`:
```dart
// Descomentar esta línea para ver reporte
await NotificationDebugger.generateFullReport(
  FeedbackScheduler.notifications,
);
```

---

## 📱 PUNTOS CLAVE ESPECÍFICOS DE MOTOROLA + ANDROID 15

### **Problema: Motorola Stock ROM bloquea alarmas exactas**
**Solución aplicada:**
1. `DeviceOptimizationHelper.applyMotorolaWorkaround()` en `FeedbackScheduler.init()`
2. Detecta si es Motorola automáticamente
3. Solicita explícitamente `SCHEDULE_EXACT_ALARM` + batería

### **Problema: Motorola Kids o Family Link restricciones**
**Solución:**
- Si el usuario tiene Family Link habilitado en la app, NO habrá notificaciones
- Usuario debe deshabilitarlo en: Configuración → Apps → Asistente Remedio → Permisos

### **Problema: Motorola Game Space**
**Solución:**
- Si la app está en Game Space, excluirla: Ajustes → Game Space → Remover Asistente Remedio

---

## 🔍 VERIFICAR QUE FUNCIONAN LAS NOTIFICACIONES

### **Test 1: Notificación Inmediata (5 segundos)**
```bash
# En el código, cambiar temporalmente:
final delayMinutes = 5; // En lugar de 20 + random.nextInt(40)

# Compilar y esperar 5 segundos
```

### **Test 2: Notificación Exacta a Hora Futura**
1. Crear recordatorio a las 21:00
2. Si son las 20:55, debe sonar a las 21:00 exacto
3. Ver logcat para confirmar `[DUE] Programada correctamente`

### **Test 3: Notificación Diferida (20-60 min)**
1. Abrir la notificación exacta
2. NO marcar medicamento durante 2 minutos
3. Debe recibir notificación preguntando "¿Lo tomaste?" en 20-60 minutos

### **Test 4: Reschedule Post-Boot**
1. Programar varios recordatorios
2. Reiniciar dispositivo
3. Debe recibir las notificaciones sin problema

---

## 🛠️ ARCHIVOS MODIFICADOS

| Archivo | Cambios |
|---------|---------|
| `android/app/src/main/AndroidManifest.xml` | Permisos Doze + FOREGROUND_SERVICE |
| `lib/services/feedback_scheduler.dart` | Sincronización de permisos + workarounds |
| `lib/services/device_optimization_helper.dart` | **NUEVO** - Helper para Motorola |
| `lib/utils/notification_debugger.dart` | **NUEVO** - Herramienta de debugging |
| `android/.../MainActivity.kt` | MethodChannel para device optimization |
| `android/.../BootReceiver.kt` | Reschedule post-boot mejorado |
| `android/.../DeviceOptimizationService.kt` | **NUEVO** - Servicio Kotlin |
| `lib/main.dart` | Manejo de reschedule + MethodChannel |

---

## ⚡ CHECKLIST PRE-DEPLOYMENT

- [ ] Compilar en `--release` sin errores
- [ ] Verificar logcat sin excepciones críticas
- [ ] Probar notificación exacta a hora futura
- [ ] Probar notificación diferida (2 min timeout)
- [ ] Probar reschedule post-boot
- [ ] Verificar que permisos se solicitan correctamente
- [ ] Usuario confirma exclusión de batería
- [ ] Permisos en Configuración → Aplicaciones → Asistente Remedio:
  - ✅ POST_NOTIFICATIONS: Permitido
  - ✅ SCHEDULE_EXACT_ALARM: Permitido
  - ✅ Batería: No optimizar
- [ ] Probar en Android 15 específicamente
- [ ] Probar en otro Motorola si es posible

---

## 📞 TROUBLESHOOTING RÁPIDO

| Síntoma | Causa Probable | Solución |
|--------|----------------|----------|
| Ninguna notificación aparece | Permiso POST_NOTIFICATIONS denegado | App Settings → Notificaciones → Activar |
| Notificación no es exacta | Sin permiso SCHEDULE_EXACT_ALARM | `DeviceOptimizationHelper.requestExactAlarmPermission()` |
| Notificación diferida no llega | App en Doze Mode | Excluir batería + revisar que no esté en Game Space |
| Notificaciones desaparecen después de reiniciar | BootReceiver no funciona | Verificar que `BOOT_COMPLETED` está en AndroidManifest |
| Logs no muestran FeedbackScheduler | Init no se ejecutó | Verificar `FeedbackScheduler.init()` en `main()` |

---

## 📝 COMANDOS ÚTILES DURANTE DEBUGGING

```bash
# Ver todos los logs en tiempo real
adb logcat

# Filtrar solo FeedbackScheduler
adb logcat | grep FeedbackScheduler

# Ver últimas 100 líneas
adb logcat -d | tail -100

# Borrar logcat
adb logcat -c

# Simular BOOT_COMPLETED
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED

# Ver permisos de la app
adb shell pm dump com.example.asistente_remedio

# Ver si está en batería restringida
adb shell cmd deviceidle get restricted

# Ver canales de notificación
adb shell cmd notification list_channels com.example.asistente_remedio

# Iniciar app específica
adb shell am start -n com.example.asistente_remedio/.MainActivity
```

---

## 💡 NOTAS IMPORTANTES

1. **Android 15 es más restrictivo** que versiones anteriores. Requiere permisos explícitos y sincronización cuidadosa.

2. **Motorola es especialmente restrictivo** con notificaciones exactas. El workaround detecta automáticamente el fabricante.

3. **Doze Mode es el enemigo #1**. Si el usuario no excluye la app, habrá problemas. La app solicita exclusión automáticamente en init.

4. **Las notificaciones diferidas (20-60 min) son las más frágiles**. Si el permiso exacto falla, caen automáticamente a inexactas, pero aún pueden llegar.

5. **Logcat es tu mejor amigo**. Lee los logs cuidadosamente, especialmente los `[INIT]`, `[DUE]`, `[DIFERIDA]` y `[ERROR]`.

6. **MethodChannels**: La app usa MethodChannels para comunicación con Kotlin. Asegúrate de que `configureFlutterEngine()` se ejecute correctamente.
