import 'package:flutter/material.dart';

import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/profile_widgets.dart';
import '../login_screen.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ProfileShell(
      onLoggedOut: (context) {
        Navigator.of(context).pushAndRemoveUntil(
          SlidePageRoute(child: const LoginScreen()),
          (route) => false,
        );
      },
      bottomNavigationBar: Container(
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E2E2),
          border: Border.all(color: const Color(0xFF9A9A9A), width: 1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            BottomNavIcon(
              icon: Icons.home_rounded,
              selected: false,
              onTap: () {
                Navigator.of(
                  context,
                ).pushReplacement(SlidePageRoute(child: const HomeScreen()));
              },
            ),
            BottomNavIcon(
              icon: Icons.grid_view_rounded,
              selected: false,
              onTap: () {
                Navigator.of(context).pushReplacement(
                  SlidePageRoute(child: const BookingHistoryScreen()),
                );
              },
            ),
            BottomNavIcon(
              icon: Icons.person_rounded,
              selected: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
