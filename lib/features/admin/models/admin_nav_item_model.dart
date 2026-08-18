import 'package:flutter/material.dart';

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
      label: 'Listings',
      icon: Icons.home_work_outlined,
      activeIcon: Icons.home_work_rounded,
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

  static List<AdminCategoryModel> get categories => const [
        AdminCategoryModel(
          index: 0,
          title: 'Mess Listings',
          icon: Icons.home_work_rounded,
        ),
        AdminCategoryModel(
          index: 1,
          title: 'Room Inquiries',
          icon: Icons.connect_without_contact_rounded,
        ),
      ];
}
