import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../routes/slide_page_route.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/history_widgets.dart';
import '../../widgets/home_widgets.dart';
import 'booking_history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.chevron_left_rounded,
                            color: AppColors.navy,
                            size: 18,
                          ),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const PaymentCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                  Navigator.of(context).pushAndRemoveUntil(
                    SlidePageRoute(child: const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
              BottomNavIcon(
                icon: Icons.receipt_long_rounded,
                selected: true,
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    SlidePageRoute(child: const BookingHistoryScreen()),
                  );
                },
              ),
              BottomNavIcon(
                icon: Icons.account_circle_rounded,
                selected: false,
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(SlidePageRoute(child: const ProfileScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pembayaran',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Center(child: QrCodeBox()),
          const SizedBox(height: 14),
          const Text(
            'Silahkan Scan QRIS tersebut dan masukkan nominal sesuai dengan tagihan anda',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 9,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Kos Xavier 1',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'Total : Rp2.500.000',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bayar sebelum 20 April 2026',
            style: TextStyle(
              color: Colors.red,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Upload Bukti Bayar',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
