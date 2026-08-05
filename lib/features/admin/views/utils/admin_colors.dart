import 'package:flutter/material.dart';

/// ===================================================================
/// [VIEW UTILS - MVC PATTERN]
/// অ্যাডমিন প্যানেলের নিজস্ব কালার প্যালেট (Slate/Dark-Neutral Theme)
/// Auth স্ক্রিনের Admin Portal বাটনের কালার কম্বিনেশনের সাথে সামঞ্জস্যপূর্ণ।
/// ===================================================================
class AdminColors {
  // Primary slate/dark-neutral palette
  static const Color pageBg        = Color(0xFFF1F5F9); // Cool Slate BG

  // Accent — deep slate (from 0xFF475569 / 0xFF0F172A)
  static const Color accentDark    = Color(0xFF0F172A); // Deep Slate (title)
  static const Color accentMid     = Color(0xFF334155); // Slate Mid (body/sub)
  static const Color accentLight   = Color(0xFF64748B); // Slate Grey (caption)

  // Borders
  static const Color border        = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF475569);

  // Status colors (Semantic - unchanged)
  static const Color statusPending  = Color(0xFFF59E0B); // Amber
  static const Color statusApproved = Color(0xFF10B981); // Emerald Green
  static const Color statusRejected = Color(0xFFEF4444); // Red

  // Hero Card Gradient (Deep Slate theme)
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
