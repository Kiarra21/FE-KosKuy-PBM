import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'providers/admin_management_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/branch_provider.dart';
import 'providers/customer_room_provider.dart';
import 'providers/owner_room_provider.dart';
import 'providers/owner_user_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const KosKuyApp());
}

class KosKuyApp extends StatelessWidget {
  const KosKuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => CustomerRoomProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => OwnerRoomProvider()),
        ChangeNotifierProvider(create: (_) => OwnerUserProvider()),
        ChangeNotifierProvider(create: (_) => AdminManagementProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'KosKuy',
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            secondary: AppColors.gold,
            surface: AppColors.white,
            onPrimary: AppColors.white,
            onSecondary: AppColors.navy,
            onSurface: AppColors.navy,
          ),
          scaffoldBackgroundColor: AppColors.white,
          splashColor: AppColors.gold.withValues(alpha: .16),
          highlightColor: AppColors.gold.withValues(alpha: .08),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
