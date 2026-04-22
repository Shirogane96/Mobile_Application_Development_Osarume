import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/security_provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final securityProvider = context.watch<SecurityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance & Security'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Visual Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildThemeTile(context, themeProvider, AppTheme.light, 'Light Mode', Icons.light_mode, Colors.teal),
          _buildThemeTile(context, themeProvider, AppTheme.dark, 'Dark Mode', Icons.dark_mode, Colors.black),
          _buildThemeTile(context, themeProvider, AppTheme.lightFilter, 'Sepia (Light Filter)', Icons.filter_vintage, Colors.orange),
          _buildThemeTile(context, themeProvider, AppTheme.pink, 'Pink Mode', Icons.favorite, Colors.pinkAccent),
          
          const SizedBox(height: 30),
          const Text('Privacy & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Require fingerprint or face ID to open app'),
              secondary: const Icon(Icons.fingerprint, color: Colors.teal),
              value: securityProvider.isLockEnabled,
              onChanged: (bool value) => securityProvider.toggleLock(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeProvider tp, AppTheme theme, String label, IconData icon, Color color) {
    final isSelected = tp.currentTheme == theme;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
        onTap: () => tp.setTheme(theme),
      ),
    );
  }
}
