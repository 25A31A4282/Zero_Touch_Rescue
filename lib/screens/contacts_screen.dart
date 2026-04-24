import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  String selectedCountryCode = "+91";
  int requiredDigits = 10;
  bool isBloodDonor = false;
  final Map<String, Map<String, dynamic>> countries = {
    "India 🇮🇳": {"code": "+91", "digits": 10},
    "USA 🇺🇸": {"code": "+1", "digits": 10},
    "UK 🇬🇧": {"code": "+44", "digits": 10},
    "UAE 🇦🇪": {"code": "+971", "digits": 9},
  };

  final List<Map<String, String>> inbuiltContacts = [
    {"name": "Police", "number": "100"},
    {"name": "Ambulance", "number": "108"},
    {"name": "Women Helpline", "number": "1091"},
    {"name": "Fire station", "number": "101"},
  ];

  final DatabaseReference db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://zerotouchrescuenew-14125-default-rtdb.firebaseio.com/',
  ).ref("contacts");

  void saveContact() {
    String name = nameController.text.trim();
    String number = numberController.text.trim();

    if (name.isEmpty || number.isEmpty) {
      _showSnackbar("Enter all fields! ❗");
      return;
    }

    if (number.length != requiredDigits) {
      _showSnackbar("Enter $requiredDigits digits for this country! ❌");
      return;
    }

    db.push().set({
      "name": name,
      "number": "$selectedCountryCode $number",
      "isBloodDonor": isBloodDonor, 
      "timestamp": ServerValue.timestamp,
    }).then((_) {
      _showSnackbar("Contact Saved Successfully ✅");
      nameController.clear();
      numberController.clear();
      setState(() => isBloodDonor = false);
      FocusScope.of(context).unfocus();
    }).catchError((error) {
      _showSnackbar("Failed to save: $error");
    });
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 🗑️ Delete Contact Function
  void deleteContact(String key) {
    db.child(key).remove().then((_) => _showSnackbar("Contact Deleted 🗑️"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ZeroTouch Contacts"), 
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController, 
                        decoration: const InputDecoration(labelText: "Contact Name", prefixIcon: Icon(Icons.person)),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: countries.keys.firstWhere((k) => countries[k]!["code"] == selectedCountryCode),
                            onChanged: (val) => setState(() {
                              selectedCountryCode = countries[val]!["code"];
                              requiredDigits = countries[val]!["digits"];
                            }),
                            items: countries.keys.map((c) => DropdownMenuItem(value: c, child: Text(countries[c]!["code"]))).toList(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: numberController,
                              keyboardType: TextInputType.phone,
                              maxLength: requiredDigits,
                              decoration: const InputDecoration(labelText: "Mobile Number", counterText: ""),
                            ),
                          ),
                        ],
                      ),
                      // 🩸 Blood Donor Toggle
                      CheckboxListTile(
                        title: const Text("Mark as Blood Donor"),
                        subtitle: const Text("Will be alerted during medical emergencies"),
                        value: isBloodDonor,
                        onChanged: (val) => setState(() => isBloodDonor = val!),
                        activeColor: Colors.red,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: saveContact, 
                          icon: const Icon(Icons.person_add),
                          label: const Text("ADD TO SECURE LIST"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(left: 20, top: 10), child: Text("🚨 INBUILT HELPLINES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)))),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final c = inbuiltContacts[index];
              return ListTile(
                leading: const Icon(Icons.security, color: Colors.red),
                title: Text(c["name"]!),
                subtitle: Text(c["number"]!),
                trailing: const Icon(Icons.call, color: Colors.green),
              );
            }, childCount: inbuiltContacts.length),
          ),

          const SliverToBoxAdapter(child: Divider()),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(left: 20, top: 10), child: Text("👨‍👩‍👧‍👦 SAVED CONTACTS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)))),

          StreamBuilder(
            stream: db.onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No contacts found."))));

              final Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map;
              final keys = map.keys.toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final key = keys[index];
                  final c = Map<String, dynamic>.from(map[key]);
                  bool isDonor = c["isBloodDonor"] ?? false;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDonor ? Colors.red.shade50 : Colors.blue.shade50,
                      child: Icon(isDonor ? Icons.bloodtype : Icons.person, color: isDonor ? Colors.red : Colors.blue),
                    ),
                    title: Text(c["name"] ?? "No Name"),
                    subtitle: Text(c["number"] ?? ""),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => deleteContact(key)),
                  );
                }, childCount: keys.length),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}