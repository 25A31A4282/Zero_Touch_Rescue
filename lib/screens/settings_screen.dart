import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBioEnabled = false;
  bool _isPrivacyEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }


  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBioEnabled = prefs.getBool('bio_security') ?? false;
      _isPrivacyEnabled = prefs.getBool('number_privacy') ?? false;
    });
  }

 
  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Confirm identity to enable Biometric Lock',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (!authenticated) return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bio_security', value);
    setState(() => _isBioEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView(
        children: [
          // --- 👤 PROFILE SECTION ---
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Account", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text("Pavani"), // Mee name auto-populate cheyochu
            subtitle: const Text("Developer Mode | Solution Challenge 2026"),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () { /* Profile Edit Logic */ },
          ),
          const Divider(),

          // --- 🔐 SECURITY & BIOMETRICS ---
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Security", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, color: Colors.blue),
            title: const Text("Biometric / Fingerprint"),
            subtitle: const Text("Use sensor to confirm safety"),
            value: _isBioEnabled,
            onChanged: _toggleBiometric,
          ),
          ListTile(
            leading: const Icon(Icons.password, color: Colors.green),
            title: const Text("Change Emergency PIN"),
            subtitle: const Text("Backup for biometric lock"),
            onTap: () { /* PIN change logic */ },
          ),

          const Divider(),

          // --- 🛡️ PRIVACY & PERMISSIONS ---
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Privacy & Permissions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.privacy_tip, color: Colors.orange),
            title: const Text("Hide Numbers in Alerts"),
            subtitle: const Text("Mask contact numbers for privacy"),
            value: _isPrivacyEnabled,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('number_privacy', val);
              setState(() => _isPrivacyEnabled = val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications, color: Colors.purple),
            title: const Text("System Permissions"),
            subtitle: const Text("Location, Mic, & Sensors status"),
            onTap: () => openAppSettings(), 
          ),

          const Divider(),
          
          // --- ℹ️ ABOUT ---
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About ZeroTouch Rescue"),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: "ZeroTouch Rescue",
                applicationVersion: "1.0.0",
                children: [const Text("AI-powered Emergency Response System.")],
              );
            },
          ),
        ],
      ),
    );
  }
}