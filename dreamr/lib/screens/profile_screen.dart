import 'package:flutter/material.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:dreamr/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;
  final VoidCallback? onDone;
  const ProfileScreen({super.key, required this.refreshTrigger, this.onDone});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _email;
  String? _firstName;
  String? _gender;
  DateTime? _birthdate;
  bool _enableAudio = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      setState(() {
        _email = data['email'];
        _firstName = data['first_name'];
        _gender = data['gender'];
        _birthdate = (data['birthdate'] != null && data['birthdate'] != '')
            ? DateTime.parse(data['birthdate'])
            : null;
        _enableAudio = data['enable_audio'] == true || data['enable_audio'] == '1';
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load profile: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    try {
      await ApiService.setProfile(
        firstName: _firstName ?? '',
        gender: _gender ?? '',
        birthdate: _birthdate,
        enableAudio: _enableAudio,
      );

      widget.refreshTrigger.value++;
      widget.onDone?.call();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile saved')),
      );
    } catch (e) {
      debugPrint('❌ Failed to save profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Failed to save profile')),
      );
    }
  }

  // to make the profile page pretty
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.purple900,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 📧 EMAIL DISPLAY
                  Text(
                    _email ?? 'unknown', // store email in state
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // 🖼️ AVATAR (future)
                  // CircleAvatar(
                  //   radius: 40,
                  //   backgroundColor: Colors.white24,
                  //   child: const Icon(Icons.person, size: 40, color: Colors.white),
                  // ),
                  // const SizedBox(height: 30),

                  // 📝 FORM CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.purple950,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // FIRST NAME
                          TextFormField(
                            initialValue: _firstName,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('First Name'),
                            onChanged: (val) => _firstName = val,
                          ),
                          const SizedBox(height: 20),

                          // GENDER
                          DropdownButtonFormField<String>(
                            value: _gender?.isNotEmpty == true ? _gender : null,
                            decoration: _inputDecoration('Gender'),
                            dropdownColor: AppColors.purple950,
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text("Male"),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text("Female"),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text("Prefer not to answer"),
                              ),
                            ],
                            onChanged: (val) => _gender = val,
                          ),
                          const SizedBox(height: 20),

                          // BIRTHDATE
                          InkWell(
                            onTap: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _birthdate ?? DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.deepPurple,
                                        surface: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) setState(() => _birthdate = picked);
                            },
                            child: InputDecorator(
                              decoration: _inputDecoration('Birthdate'),
                              child: Text(
                                _birthdate == null
                                    ? 'Tap to select'
                                    : _birthdate!.toLocal().toString().split(' ')[0],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // AUDIO SWITCH
                          SwitchListTile(
                            title: Text(
                              _enableAudio ? "Audio Enabled" : "Audio Disabled",
                              style: const TextStyle(color: Colors.white),
                            ),
                            value: _enableAudio,
                            onChanged: (val) => setState(() => _enableAudio = val),
                            activeColor: Colors.white,
                            inactiveThumbColor: Colors.grey,
                            inactiveTrackColor: Colors.white30,
                          ),

                          const SizedBox(height: 30),

                          // CANCEL and SAVE BUTTONs
                          Row(
                            children: [
                              // ✅ Cancel button
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // just go back to previous page (journal)
                                    widget.onDone?.call();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white70),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // ✅ Save button
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurpleAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text(
                                    "Save",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
