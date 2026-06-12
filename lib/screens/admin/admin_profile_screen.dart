import 'package:flutter/material.dart';

import '../../routes/slide_page_route.dart';
import '../../widgets/profile_widgets.dart';
import '../login_screen.dart';
import 'admin_bottom_nav.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      bottomNavigationBar: const AdminBottomNav(selectedIndex: 3),
      onLoggedOut: (context) {
        Navigator.of(context).pushAndRemoveUntil(
          SlidePageRoute(child: const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
