import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables to control editabilitya
  bool _isEditingName = false;
  bool _isEditingPassword = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = user?.displayName ?? '';
  }

  Future<void> _updateDisplayName() async {
    try {
      await user?.updateDisplayName(_nameController.text);
      if (!mounted) return;
      setState(() => _isEditingName = false); // Lock field after saving
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name updated!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  

  Future<void> _updatePassword() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    // 1. Check if the user is a password user or a Google user
    bool isPasswordUser = false;
    for (var profile in currentUser?.providerData ?? []) {
      if (profile.providerId == 'password') {
        isPasswordUser = true;
        break;
      }
    }

    try {
      if (isPasswordUser) {
        // Existing logic: Ask for current password and re-authenticate
        String? currentPassword = await _showPasswordDialog('Enter Current Password');
        if (currentPassword == null) return;

        AuthCredential credential = EmailAuthProvider.credential(
          email: currentUser!.email!,
          password: currentPassword,
        );
        await currentUser.reauthenticateWithCredential(credential);
      } else {
        // Google User logic: Trigger the Google Sign-In flow again
        // This provides the "fresh" credential needed for sensitive operations
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await currentUser?.reauthenticateWithProvider(googleProvider);
      }

      // 2. Perform the actual password update
      await currentUser?.updatePassword(_passwordController.text);
      
      // ... rest of your snackbar/UI logic
    } catch (e) {
      // Handle errors (wrong password, canceled sign-in, etc.)[cite: 2]
    }
  }

  Future<String?> _showPasswordDialog(String title) async {
    String password = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Password'),
          onChanged: (value) => password = value,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, password), child: const Text('Confirm')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String displayName = user?.displayName ?? 'User';
    final String initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        backgroundColor: const Color.fromARGB(255, 183, 58, 58),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: const Color.fromARGB(255, 183, 58, 58),
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null 
                  ? Text(initials, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)) 
                  : null,
            ),
            const SizedBox(height: 20),
            Text(user?.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const Divider(height: 40),

            // Display Name Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    enabled: _isEditingName, // Controlled by pencil tap
                    decoration: InputDecoration(
                      labelText: 'Display Name',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: !_isEditingName,
                      fillColor: _isEditingName 
                        ? Colors.transparent 
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  // Switch between Edit (pencil) and Save (check) icons[cite: 2]
                  icon: Icon(_isEditingName ? Icons.check_circle : Icons.edit, 
                             color: _isEditingName ? Colors.green : Colors.blue),
                  onPressed: () {
                    if (_isEditingName) {
                      _updateDisplayName();
                    } else {
                      setState(() => _isEditingName = true);
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Password Field[cite: 1, 2]
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    enabled: _isEditingPassword, // Controlled by pencil tap[cite: 2]
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      filled: !_isEditingPassword,
                      fillColor: _isEditingName 
                        ? Colors.transparent 
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isEditingPassword ? Icons.check_circle : Icons.edit, 
                             color: _isEditingPassword ? Colors.green : Colors.red),
                  onPressed: () {
                    if (_isEditingPassword) {
                      _updatePassword();
                    } else {
                      setState(() => _isEditingPassword = true);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}