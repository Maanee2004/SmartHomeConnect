import 'package:flutter/material.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/screens/dashboard/dashboard_screen.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Dashboard admin pour une maison (utilisateur propriétaire).
class AdminHouseDetailScreen extends StatefulWidget {
  const AdminHouseDetailScreen({super.key, required this.house});

  final HouseSummary house;

  @override
  State<AdminHouseDetailScreen> createState() => _AdminHouseDetailScreenState();
}

class _AdminHouseDetailScreenState extends State<AdminHouseDetailScreen> {
  @override
  void initState() {
    super.initState();
    FirestoreHomeRepository.instance
        .setAdminTargetUser(widget.house.ownerUserId);
  }

  @override
  void dispose() {
    FirestoreHomeRepository.instance.setAdminTargetUser(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded,
              color: context.smartColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.house.ownerName,
              style: TextStyle(
                color: context.smartColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              widget.house.ownerEmail,
              style: TextStyle(
                color: context.smartColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: DashboardScreen(
        readOnly: false,
        embedded: true,
        showHeader: false,
        houseTitlePrefix: 'Gestion des appareils',
      ),
    );
  }
}
