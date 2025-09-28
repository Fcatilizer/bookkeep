import 'package:flutter/material.dart';
import 'account_details.dart';
import 'data_privacy_page.dart';
// import 'customize_report_page.dart'; // Commented out - finish later
import 'appearance_page.dart';
import 'about_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<_SettingItem> items = [
    _SettingItem(icon: Icons.account_circle, title: 'Account'),
    _SettingItem(icon: Icons.lock, title: 'Data and Privacy'),
    // _SettingItem(icon: Icons.assessment, title: 'Customize Report'), // Commented out - finish later
    _SettingItem(icon: Icons.palette, title: 'Appearance'),
    _SettingItem(icon: Icons.info, title: 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: Icon(item.icon),
          title: Text(item.title),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            _handleItemTap(context, item.title);
          },
        );
      },
    );
  }

  void _handleItemTap(BuildContext context, String title) {
    switch (title) {
      case 'Account':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountDetailsPage()),
        );
        break;
      case 'Data and Privacy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DataPrivacyPage()),
        );
        break;
      // case 'Customize Report': // Commented out - finish later
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => const CustomizeReportPage()),
      //   );
      //   break;
      case 'Appearance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AppearancePage()),
        );
        break;
      case 'About':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        );
        break;
    }
  }
}

class _SettingItem {
  final IconData icon;
  final String title;

  const _SettingItem({required this.icon, required this.title});
}
