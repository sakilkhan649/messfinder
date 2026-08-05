import 'package:flutter/material.dart';
import '../../../core/utils/app_constants.dart';

/// ===================================================================
/// [MODEL LAYER - MVC PATTERN]
/// অ্যাডমিন প্যানেলের নেভিগেশন ও ক্যাটাগরি আইটেমের ডেটা মডেল।
/// UI-তে সরাসরি হার্ডকোড না করে এই মডেল থেকে আইটেমগুলো লোড করা হয়।
/// ===================================================================

/// বটম নেভিগেশন বারের প্রতিটি আইটেমের মডেল
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

  /// অ্যাডমিন ড্যাশবোর্ডের ৩টি প্রধান ট্যাব
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

/// Requests ট্যাবের ক্যাটাগরি চিপসের (Bachelor Bookings vs Mess Listings) মডেল
class AdminCategoryModel {
  final int index;
  final String title;
  final IconData icon;

  const AdminCategoryModel({
    required this.index,
    required this.title,
    required this.icon,
  });

  /// অ্যাডমিন প্যানেলে অনুমোদনের জন্য থাকা ২টি ক্যাটাগরি
  static List<AdminCategoryModel> get categories => [
        AdminCategoryModel(
          index: 0,
          title: 'Bookings (৳${AppConstants.bachelorFee})',
          icon: Icons.school_rounded,
        ),
        AdminCategoryModel(
          index: 1,
          title: 'Mess Posts (৳${AppConstants.landlordFee})',
          icon: Icons.home_work_rounded,
        ),
      ];
}
