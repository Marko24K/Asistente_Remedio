import 'package:flutter/services.dart';
import 'dart:io' show Platform;

/// Helper para manejar optimizaciones de batería específicas de fabricantes
/// y workarounds para Android 15 (especialmente Motorola)
class DeviceOptimizationHelper {
  static const platform = MethodChannel('com.example.asistente_remedio/device');

  // =========================================================
  // SOLICITAR EXCLUSIÓN DE OPTIMIZACIÓN DE BATERÍA
  // =========================================================
  static Future<bool> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return true;

    try {
      print('🔋 [DEVICE] Solicitando exclusión de optimización de batería...');

      final result = await platform.invokeMethod<bool>(
        'requestIgnoreBatteryOptimization',
      );

      if (result == true) {
        print('✅ [DEVICE] Se solicitó exclusión de batería al usuario');
        return true;
      } else {
        print('⚠️  [DEVICE] Usuario rechazó exclusión de batería');
        return false;
      }
    } catch (e) {
      print('❌ [DEVICE] Error solicitando exclusión: $e');
      return false;
    }
  }

  // =========================================================
  // OBTENER INFORMACIÓN DEL DISPOSITIVO
  // =========================================================
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (!Platform.isAndroid) return {};

    try {
      print('📱 [DEVICE] Obteniendo información del dispositivo...');

      final result = await platform.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceInfo',
      );

      if (result != null) {
        final info = Map<String, dynamic>.from(result);
        print('   Fabricante: ${info['manufacturer']}');
        print('   Modelo: ${info['model']}');
        print('   Android: ${info['android_version']}');
        return info;
      }
      return {};
    } catch (e) {
      print('❌ [DEVICE] Error obteniendo info: $e');
      return {};
    }
  }

  // =========================================================
  // VERIFICAR SI ES MOTOROLA
  // =========================================================
  static Future<bool> isMotorola() async {
    final info = await getDeviceInfo();
    final manufacturer = (info['manufacturer'] as String?)?.toLowerCase() ?? '';
    return manufacturer.contains('motorola') || manufacturer.contains('moto');
  }

  // =========================================================
  // APLICAR WORKAROUND MOTOROLA ANDROID 15
  // =========================================================
  static Future<void> applyMotorolaWorkaround() async {
    if (!Platform.isAndroid) return;

    final isMoto = await isMotorola();
    if (!isMoto) {
      print('⚠️  [MOTO] No es Motorola, ignorando workaround');
      return;
    }

    print('🎯 [MOTO] Aplicando workarounds para Motorola Android 15...');

    try {
      // 1. Solicitar exclusión de batería
      await requestIgnoreBatteryOptimization();

      // 2. Solicitar exacto explícito
      print('⏰ [MOTO] Solicitando permiso SCHEDULE_EXACT_ALARM explícito...');
      final hasExactPermission = await platform.invokeMethod<bool>(
        'requestExactAlarmPermission',
      );

      if (hasExactPermission == true) {
        print('✅ [MOTO] Permisos de alarma exacta otorgados');
      } else {
        print('⚠️  [MOTO] Permisos de alarma exacta denegados');
      }

      print('✅ [MOTO] Workarounds aplicados');
    } catch (e) {
      print('❌ [MOTO] Error aplicando workarounds: $e');
    }
  }
}
