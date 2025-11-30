# Guía de Depuración de Notificaciones - Asistente Remedios

## Problemas Encontrados y Soluciones Aplicadas

### 1. ❌ PROBLEMA: Icono de notificación inválido
**Causa:** Se usaba `@mipmap/ic_launcher` que es un recurso mipmap, no un drawable válido para notificaciones.
**Solución:** ✅ Cambiado a `app_icon` (más genérico y compatible).

### 2. ❌ PROBLEMA: Canales sin configuración de DND (Do Not Disturb)
**Causa:** Los canales no tenían `bypassDnd: true`, por lo que podrían ser silenciados por modo No Molestar.
**Solución:** ✅ Agregado `bypassDnd: true` a ambos canales.

### 3. ❌ PROBLEMA: Falta verificación de canales en tiempo de ejecución
**Causa:** Los canales se creaban solo en `init()`. Si la app se reinstalaba, los canales no se recreaban.
**Solución:** ✅ Agregado método `_ensureChannelsAndPermissions()` que se llama antes de cada notificación programada.

### 4. ❌ PROBLEMA: Permisos no verificados en tiempo de ejecución
**Causa:** Los permisos se pedían solo en init(). El usuario podría revocarlos después.
**Solución:** ✅ El método `_ensureChannelsAndPermissions()` verifica permisos actualizado cada vez.

### 5. ❌ PROBLEMA: Falta de permisos adicionales de wake-lock
**Causa:** Las notificaciones en la pantalla bloqueada necesitaban DISABLE_KEYGUARD y WAKE_LOCK.
**Solución:** ✅ Agregados permisos en AndroidManifest.xml.

### 6. ❌ PROBLEMA: MainActivity no verifica estado de canales
**Causa:** Sin logs del estado de canales, era difícil diagnosticar problemas.
**Solución:** ✅ MainActivity ahora loguea canales al iniciar (visible en `adb logcat`).

## Pasos de Depuración Manual

### Paso 1: Verificar Canales en el Dispositivo
```bash
adb shell dumpsys notification | grep -A 5 "due_channel\|feedback_channel"
```
Debería mostrar dos canales con importancia 4 (max).

### Paso 2: Ver Logs de Flutter
```bash
flutter logs
# O con adb:
adb logcat | grep -E "FeedbackScheduler|MainActivity|flutter"
```

### Paso 3: Forzar Recreación de Canales
1. Abre el app
2. Mira los logs para ver "✅ Canales creados"
3. Si no aparecen, hay un problema en AndroidFlutterLocalNotificationsPlugin

### Paso 4: Verificar Permisos en el Dispositivo
**Ajustes > Aplicaciones > Asistente Remedios > Permisos**
- POST_NOTIFICATIONS: DEBE estar permitido
- Alarmas exactas: DEBE estar permitido

### Paso 5: Reinstalar Limpiamente
```bash
flutter clean
flutter pub get
flutter run --release
```

### Paso 6: Probar Notificación Manual
En la app, crea un recordatorio con hora futura cercana (ej: en 2 minutos).
Deberías ver en logs:
```
📌 [NOTIF DUE] Programando notificación exacta:
   ID: 2001
   Medicamento: Ibuprofeno
   ...
✅ Notificación exacta programada
```

## Información del Dispositivo

### Motorola G34 5G
- Android 13+
- Requiere POST_NOTIFICATIONS (Android 13+)
- Soporta exactAllowWhileIdle
- NOTA: Algunos Motorolas tienen "Adaptive Battery" que puede pausar alarmas

**Solución para Motorola:**
1. Ajustes > Batería y Cuidado del Dispositivo > Optimización de batería
2. Busca "Asistente Remedios"
3. Establece como "No optimizado" o "Sin restricciones"

### Motorola Edge 40
- Android 13/14
- Requiere POST_NOTIFICATIONS
- Similar a G34

**Solución para Edge 40:**
Mismo proceso que G34 en Optimización de batería.

## Cambios Realizados en Código

### 1. `feedback_scheduler.dart`
- ✅ Icono cambiado de `@mipmap/ic_launcher` a `app_icon`
- ✅ Agregado `bypassDnd: true` en ambos canales
- ✅ Agregado método `_ensureChannelsAndPermissions()` (reutilizable, idempotente)
- ✅ Llamadas a `_ensureChannelsAndPermissions()` antes de `zonedSchedule()`

### 2. `MainActivity.kt`
- ✅ Agregado logging de canales de notificación en `onStart()`
- ✅ Verifica Android version y API level

### 3. `AndroidManifest.xml`
- ✅ Agregado `DISABLE_KEYGUARD`
- ✅ Agregado `WAKE_LOCK`

## Validación

Para confirmar que todo funciona:

1. **Build limpio:**
   ```bash
   flutter clean && flutter pub get
   ```

2. **Ejecutar en debug:**
   ```bash
   flutter run
   ```

3. **Monitorear logs:**
   ```bash
   flutter logs
   ```

4. **Crear recordatorio de prueba:**
   - Crea recordatorio con hora dentro de 2-5 minutos
   - Verifica logs en tiempo real
   - Espera a que la hora llegue
   - La notificación DEBE aparecer

5. **Si no aparece:**
   - Verifica logs para errores
   - Confirma permisos en Ajustes > Aplicaciones > Asistente Remedios
   - Revisa optimización de batería (para Motorola)
   - Intenta `adb shell dumpsys notification` para ver estado global

## Notas Importantes

- Los canales son **idempotentes**: llamar `createNotificationChannel` con el mismo ID múltiples veces es seguro.
- Los permisos se solicitan en `requestNotificationsPermission()`, que muestra diálogo al usuario.
- `fullScreenIntent: true` requiere permisos especiales en Android 10+.
- `bypassDnd: true` requiere POST_NOTIFICATIONS en Android 13+.

## Resumen de Correcciones

| Problema | Estado | Impacto |
|----------|--------|--------|
| Icono inválido | ✅ Corregido | Alto - causa fallos silenciosos |
| Sin DND bypass | ✅ Corregido | Alto - notificaciones silenciadas |
| Canales no verificados runtime | ✅ Corregido | Alto - falla tras reinstalar |
| Permisos no verificados runtime | ✅ Corregido | Medio - falla si revoca permisos |
| Falta de wake-lock | ✅ Corregido | Medio - notificación no llega en pantalla bloqueada |
| Sin logs de diagnóstico | ✅ Corregido | Bajo - solo útil para debug |

