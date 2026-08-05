import 'package:flutter/material.dart';
import '../../auth/models/user_model.dart';
import '../../bachelor/views/bachelor_main_screen.dart';
import '../../landlord/views/landlord_main_screen.dart';

class UserHomeScreen extends StatelessWidget {
  final UserModel user;

  const UserHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.isLandlord) {
      return LandlordMainScreen(user: user);
    } else {
      return BachelorMainScreen(user: user);
    }
  }
}
