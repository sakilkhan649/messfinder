import 'package:flutter/material.dart';
import '../../../core/utils/app_constants.dart';

/// ===================================================================
/// [MODEL LAYER - MVC PATTERN]
/// ===================================================================

class AdminNavItemModel {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const AdminNavItemModel({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  static const List<AdminNavItemModel> navItems = [
    AdminNavItemModel(
      index: 0,
      label: 'Overview',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    AdminNavItemModel(
      index: 1,
      label: 'Requests',
      icon: Icons.pending_actions_outlined,
      activeIcon: Icons.pending_actions_rounded,
    ),
    AdminNavItemModel(
      index: 2,
      label: 'Users',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
    ),
    AdminNavItemModel(
      index: 3,
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];
}

class AdminCategoryModel {
  final int index;
  final String title;
  final IconData icon;

  const AdminCategoryModel({
    required this.index,
    required this.title,
    required this.icon,
  });

  static List<AdminCategoryModel> get categories => [
        AdminCategoryModel(
          index: 0,
          title: 'Bookings (Tk.${AppConstants.bachelorFee})',
          icon: Icons.school_rounded,
        ),
        AdminCategoryModel(
          index: 1,
          title: 'Mess Posts (Tk.${AppConstants.landlordFee})',
          icon: Icons.home_work_rounded,
        ),
      ];
}
