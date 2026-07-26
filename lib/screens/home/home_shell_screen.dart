import 'package:flutter/material.dart';
import 'package:smart_home/screens/dashboard/dashboard_screen.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/screens/home/pieces_screen.dart';
import 'package:smart_home/screens/home/profile_screen.dart';
import 'package:smart_home/screens/home/settings_screen.dart';
import 'package:smart_home/widgets/app_brand_header.dart';
import 'package:smart_home/widgets/dashboard_bottom_bar.dart';

/// Conteneur principal après connexion : dashboard + pièces + profil + paramètres.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _tab = 0;
  String? _dashboardFocusRoomId;

  void _selectTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
  }

  void _openDashboardForRoom(String roomId) {
    setState(() {
      _dashboardFocusRoomId = roomId;
      _tab = 0;
    });
  }

  Widget _bottomBar() {
    return DashboardBottomBar(
      selectedIndex: _tab,
      onSelect: _selectTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.smartColors.scaffoldBackground,
      body: Column(
        children: [
          const SafeArea(
            bottom: false,
            child: AppBrandHeader(compact: true, showTagline: false),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: context.responsive.maxContentWidth,
                ),
                child: IndexedStack(
                  index: _tab,
                  children: [
                    DashboardScreen(
                      bottomNavigationBar: _bottomBar(),
                      onGoHome: () => _selectTab(0),
                      focusRoomId: _dashboardFocusRoomId,
                    ),
                    PiecesScreen(
                      bottomNavigationBar: _bottomBar(),
                      onOpenDashboard: () => _selectTab(0),
                      onBrowseRoom: _openDashboardForRoom,
                    ),
                    ProfileScreen(bottomNavigationBar: _bottomBar()),
                    SettingsScreen(bottomNavigationBar: _bottomBar()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
