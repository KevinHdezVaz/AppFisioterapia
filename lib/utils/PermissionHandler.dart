import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PermissionHandler {
  static Future<bool> checkAndRequestMicrophonePermission(BuildContext context) async {
    try {
      var status = await Permission.microphone.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        status = await Permission.microphone.request();
        if (status.isGranted) {
          return true;
        }
      }

      if (status.isPermanentlyDenied) {
        _showSettingsSnackBar(context);
        return false;
      }

      _showErrorSnackBar(context, 'Se requieren permisos de micrófono para continuar.');
      return false;
    } catch (e) {
      _showErrorSnackBar(context, 'Error al verificar permisos: $e');
      return false;
    }
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.tr()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

static void _showSettingsSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('microphonePermissionDenied'.tr()),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: SnackBarAction(
        label: 'settings'.tr(),
        textColor: Colors.white,
        onPressed: () {
          openAppSettings();
        },
      ),
    ),
  );
}
}