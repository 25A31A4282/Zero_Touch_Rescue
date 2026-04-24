import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'settings_screen.dart'; 
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:rxdart/rxdart.dart';

// --- 🔐 1. SECURITY SERVICE (AES Encryption) ---
class SecurityService {
  static final _key = encrypt.Key.fromUtf8('my32characterslongsecretkey12345'); 
  static final _iv = encrypt.IV.fromLength(16);
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  static String encryptData(String text) => _encrypter.encrypt(text, iv: _iv).base64;
  static String decryptData(String text) => _encrypter.decrypt64(text, iv: _iv);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _secondsLeft = 10; 
  Timer? _emergencyTimer;
  bool _isAlertActive = false;
  String _emergencyType = "General";
  final stt.SpeechToText _speech = stt.SpeechToText();
  final LocalAuthentication auth = LocalAuthentication();

  // Default Crisis Contacts
  List<Map<String, String>> savedContacts = [
    {'name': 'Police', 'phone': '100'},
    {'name': 'Ambulance', 'phone': '108'},
    {'name': 'Women Helpline', 'phone': '1091'},
    {'name': 'Fire Station', 'phone': '101'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

 Future<void> _initApp() async {
    await [Permission.microphone, Permission.location, Permission.notification].request();
    await _loadSavedContacts();
    _startMonitors();
  
   // ✅ BACKGROUND SERVICE
    await FlutterForegroundTask.startService(
      notificationTitle: 'ZeroTouch Rescue',
      notificationText: 'Monitoring in background...',
    );
  }

  // --- 🎙️ VOICE & 📉 FALL DETECTION ---
  void _startMonitors() {
    accelerometerEvents
    .throttleTime(const Duration(milliseconds: 500))
    .listen((event) {
      if (event.z.abs() > 25 || event.y.abs() > 25 || event.x.abs() > 25) {
        if (!_isAlertActive) _triggerEmergencyFlow(type: "ACCIDENT");
      }
    });
    _initVoice();
  }

  void _initVoice() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            Future.delayed(const Duration(seconds: 3), () => _initVoice());
          }
        },
        onError: (err) => debugPrint("Speech Error: $err"),
      );

      if (available) {
        _speech.listen(
          onResult: (result) {
            String words = result.recognizedWords.toLowerCase();
            if (words.contains("help") || words.contains("save me")) {
              _triggerEmergencyFlow(type: "CRIME");
            } else if (words.contains("fire")) {
              _triggerEmergencyFlow(type: "FIRE");
            }
          },
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
        );
      }
    } catch (e) {
      debugPrint("Voice Init Failed: $e");
    }
  }

  void _triggerEmergencyFlow({required String type}) {
    if (_isAlertActive) return;
    setState(() { 
      _isAlertActive = true; 
      _secondsLeft = 10; 
      _emergencyType = type; 
    });
    _showEmergencyDialog();
  }

  // --- 🚨 SOS ALERT ---
  Future<void> _sendEmergencyAlerts() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String mapUrl = "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
    debugPrint("SOS SENT! To: $_emergencyType. Location: $mapUrl");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("SOS Sent with Location! 🚨"), backgroundColor: Colors.red)
    );
    setState(() { _isAlertActive = false; });
  }
  // --- 🔐 BIOMETRIC ---
  Future<void> _verifySafety() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('bio_security') ?? false) {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Confirm safety to stop SOS',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
        );
        if (authenticated) _resetAlert();
      } catch (e) { _resetAlert(); }
    } else { _resetAlert(); }
  }

  void _resetAlert() {
    _emergencyTimer?.cancel();
    setState(() { _isAlertActive = false; _secondsLeft = 10; });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Safety Confirmed ✅"), backgroundColor: Colors.green));
  }

  // --- 💾 OFFLINE STORAGE (Fixed Persistence Logic) ---
  Future<void> _persistContacts() async {
    final prefs = await SharedPreferences.getInstance();
    if (savedContacts.length > 4) {
      List<Map<String, String>> toSave = savedContacts.sublist(4).map((c) => {
        'name': c['name']!,
        'phone': SecurityService.encryptData(c['phone']!), // Encryption active
      }).toList();
      await prefs.setString('user_contacts', jsonEncode(toSave));
    } else {
      await prefs.remove('user_contacts');
    }
  }

  Future<void> _loadSavedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('user_contacts');
    if (data != null) {
      try {
        List<dynamic> decoded = jsonDecode(data);
        List<Map<String, String>> loadedList = [];
       
        loadedList.addAll([
          {'name': 'Police', 'phone': '100'},
          {'name': 'Ambulance', 'phone': '108'},
          {'name': 'Women Helpline', 'phone': '1091'},
          {'name': 'Fire Station', 'phone': '101'},
        ]);
      
        for (var c in decoded) {
          loadedList.add({
            'name': c['name'].toString(),
            'phone': SecurityService.decryptData(c['phone'].toString()),
          });
        }
        setState(() {
          savedContacts = loadedList;
        });
      } catch (e) {
        debugPrint("Error loading contacts: $e");
      }
    }
  }

  // --- 🌍 ADD/DELETE CONTACT ---
  void _showAddContactDialog(StateSetter setSheetState) {
    TextEditingController nC = TextEditingController();
    TextEditingController pC = TextEditingController();
    String selectedCode = "+91";
    Map<String, int> limits = {'+91': 10, '+1': 10, '+44': 11, '+971': 9};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDS) => AlertDialog(
        title: const Text("Add Trusted Contact"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nC, decoration: const InputDecoration(labelText: "Name")),
          Row(children: [
            DropdownButton<String>(
              value: selectedCode,
              items: limits.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setDS(() { selectedCode = v!; pC.clear(); }),
            ),
            Expanded(child: TextField(controller: pC, keyboardType: TextInputType.phone, maxLength: limits[selectedCode], decoration: const InputDecoration(counterText: ""))),
          ]),
        ]),
        actions: [
          ElevatedButton(onPressed: () {
            if (pC.text.length == limits[selectedCode]) {
              setState(() {
                savedContacts.add({'name': nC.text, 'phone': '$selectedCode ${pC.text}'});
              });
           
              _persistContacts(); 
              setSheetState(() {}); 
              Navigator.pop(context);
            }
          }, child: const Text("Save")),
        ],
      )),
    );
  }

  void _showContactsSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, setSS) => Container(
        padding: const EdgeInsets.all(20), height: MediaQuery.of(context).size.height * 0.7,
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Trusted Contacts", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30), onPressed: () => _showAddContactDialog(setSS)),
          ]),
          const Divider(),
          Expanded(child: ListView.builder(itemCount: savedContacts.length, itemBuilder: (context, i) => ListTile(
            leading: CircleAvatar(child: Icon(i < 4 ? Icons.security : Icons.person)),
            title: Text(savedContacts[i]['name']!), subtitle: Text(savedContacts[i]['phone']!),
            trailing: i < 4 ? null : IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () {
              setState(() => savedContacts.removeAt(i)); 
              _persistContacts(); 
              setSS(() {}); 
            }),
          ))),
        ]),
      )),
    );
  }

  
  void _showEmergencyDialog() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setDS) {
      _emergencyTimer?.cancel();
      _emergencyTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_secondsLeft > 0) { if (mounted) setDS(() => _secondsLeft--); }
        else { t.cancel(); Navigator.pop(context); _sendEmergencyAlerts(); }
      });
      return AlertDialog(
        title: Text("🚨 $_emergencyType DETECTED"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Sending SOS in:"),
          Text("$_secondsLeft", style: const TextStyle(fontSize: 45, color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        actions: [TextButton(onPressed: _verifySafety, child: const Text("I AM SAFE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))],
      );
    }));
  }
  @override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _speech.stop();
  } else if (state == AppLifecycleState.resumed) {
    _initVoice();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ZeroTouch Rescue"), backgroundColor: Colors.redAccent, centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())))],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(15),
            child: GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
              children: [
                _buildCard(Icons.contacts, "Contacts", Colors.blue, _showContactsSheet),
                _buildCard(Icons.bloodtype, "Donors", Colors.red, () => _showDonorsDialog()),
                _buildCard(Icons.warning_amber, "Disaster", Colors.teal, () => _triggerEmergencyFlow(type: "DISASTER")),
                _buildCard(Icons.local_hospital, "Medical", Colors.orange, () => _triggerEmergencyFlow(type: "MEDICAL")),
                _buildCard(Icons.policy, "Crime", Colors.indigo, () => _triggerEmergencyFlow(type: "CRIME")),
                _buildCard(Icons.local_fire_department, "Fire", Colors.redAccent, () => _triggerEmergencyFlow(type: "FIRE")),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _showDonorsDialog() {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Nearby Blood Donors"),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Icon(Icons.person), title: Text("Ravi (A+ve)"), subtitle: Text("0.5 km")),
        ListTile(leading: Icon(Icons.person), title: Text("Suresh (O-ve)"), subtitle: Text("1.2 km")),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
    ));
  }
  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(25), 
    color: Colors.redAccent, 
    width: double.infinity,
    child: Column(
      children: [
        
        Image.asset(
          'assets/images/logo.png',
          height: 80, 
          errorBuilder: (context, error, stackTrace) {
           
            return const Icon(Icons.shield, color: Colors.white, size: 60);
          },
        ),
        const SizedBox(height: 15),
        const Text(
          "SYSTEM MONITORING ACTIVE", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
      ],
    ),
  );
  Widget _buildCard(IconData i, String t, Color c, VoidCallback o) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)]),
    child: InkWell(onTap: o, borderRadius: BorderRadius.circular(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 40, color: c), const SizedBox(height: 10), Text(t, style: const TextStyle(fontWeight: FontWeight.bold))])),
  );

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _emergencyTimer?.cancel();
  _speech.stop();
  FlutterForegroundTask.stopService();
  super.dispose();
}
}