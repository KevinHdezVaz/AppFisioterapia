// Modal para Configuración
import 'package:LumorahAI/services/storage_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SettingsModal extends StatefulWidget {
  final VoidCallback onSignOut;

  const SettingsModal({required this.onSignOut, Key? key}) : super(key: key);

  @override
  _SettingsModalState createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  final StorageService _storageService = StorageService();
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkThemeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final soundPref = await _storageService.getString('sound_enabled');
    final vibrationPref = await _storageService.getString('vibration_enabled');

    setState(() {
      _soundEnabled = soundPref == null ? true : soundPref == 'true';
      _vibrationEnabled =
          vibrationPref == null ? true : vibrationPref == 'true';
    });
  }

  Future<void> _saveChanges() async {
    await _storageService.saveString('sound_enabled', _soundEnabled.toString());
    await _storageService.saveString(
        'vibration_enabled', _vibrationEnabled.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('settings_saved'.tr()),
        backgroundColor: Color(0xFF4ECDC4).withOpacity(0.9),
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      elevation: 12,
      backgroundColor: Color(0xFFFDF8F2).withOpacity(0.95),
      contentPadding: EdgeInsets.all(20),
      title: Center(
        child: Text(
          'settings'.tr(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8, // Modal más grande
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.grey[300], thickness: 1),
              _buildSettingTile(
                title: 'sound'.tr(),
                subtitle: 'enable_or_disable_sound'.tr(),
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
                icon: Icons.volume_up,
              ),
              Divider(color: Colors.grey[300], thickness: 1),
              _buildSettingTile(
                title: 'vibration'.tr(),
                subtitle: 'enable_or_disable_vibration'.tr(),
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
                icon: Icons.vibration,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4ECDC4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: Text(
                    'save'.tr(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF4ECDC4), size: 28),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w400,
          fontSize: 14,
          color: Colors.black54,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF4ECDC4),
        activeTrackColor: Color(0xFF88D5C2).withOpacity(0.5),
      ),
    );
  }
}
