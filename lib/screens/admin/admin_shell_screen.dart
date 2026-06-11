import 'package:flutter/material.dart';
import 'package:smart_home/screens/admin/admin_houses_screen.dart';
import 'package:smart_home/screens/admin/admin_profile_screen.dart';
import 'package:smart_home/screens/admin/admin_users_screen.dart';
import 'package:smart_home/widgets/admin_bottom_bar.dart';
import 'package:smart_home/widgets/app_brand_header.dart';

/// Interface administrateur après login (`role: admin`).
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tab = 0;

  void _selectTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
  }

  Widget _bottomBar() {
    return AdminBottomBar(
      selectedIndex: _tab,
      onSelect: _selectTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SafeArea(
          bottom: false,
          child: AppBrandHeader(compact: true, showTagline: false),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              AdminHousesScreen(bottomNavigationBar: _bottomBar()),
              AdminUsersScreen(bottomNavigationBar: _bottomBar()),
              AdminProfileScreen(bottomNavigationBar: _bottomBar()),
            ],
          ),
        ),
      ],
    );
  }
}
