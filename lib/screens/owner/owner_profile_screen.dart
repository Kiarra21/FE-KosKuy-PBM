import 'package:flutter/material.dart';

import '../../routes/slide_page_route.dart';
import '../../widgets/profile_widgets.dart';
import '../login_screen.dart';
import 'owner_bottom_nav.dart';

class OwnerProfileScreen extends StatefulWidget {
  const OwnerProfileScreen({super.key});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      bottomNavigationBar: const OwnerBottomNav(selectedIndex: 4),
      onLoggedOut: (context) {
        Navigator.of(context).pushAndRemoveUntil(
          SlidePageRoute(child: const LoginScreen()),
          (route) => false,
        );
      },
    );
  }
}
