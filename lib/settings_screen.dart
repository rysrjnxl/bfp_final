import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/account_settings.dart';
import 'services/alarm_history.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? 'Unknown User';
    final String email = user?.email ?? '';
    final String initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color.fromARGB(255, 183, 58, 58),
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 183, 58, 58)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'BFP Personnel',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color.fromARGB(255, 183, 58, 58),
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Section label
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'MENU',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2),
          ),
        ),

        // Options
         _buildOption(
          context,
          icon: Icons.account_circle,
          label: 'Account Settings',
          subtitle: 'Account info',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountSettingsPage()),
            );
          },
        ),
        _buildOption(
          context,
          icon: Icons.history,
          label: 'Alarm History',
          subtitle: 'View past fire alerts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlarmHistoryPage()),
            );
          },
        ),
        _buildOption(
          context,
          icon: Icons.settings,
          label: 'App Settings',
          subtitle: 'App preferences',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color.fromARGB(255, 183, 58, 58),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}