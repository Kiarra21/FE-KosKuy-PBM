import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/review_item.dart';
import '../../services/review_service.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/home_widgets.dart';
import '../../widgets/review_widgets.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.branchId, required this.branchName});

  final int branchId;
  final String branchName;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _loading = true;
  String? _error;
  BranchReviewStats? _stats;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats =
          await const ReviewService().fetchBranchReviewStats(widget.branchId);
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat ulasan.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(),
              SizedBox(
                height: 2,
                child: _loading
                    ? const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.gold),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: _fetchReviews,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Row(
                          children: [
                            Icon(Icons.chevron_left_rounded,
                                color: AppColors.navy, size: 18),
                            Text(
                              'Kembali',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Semua Ulasan — ${widget.branchName}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_loading)
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold),
                          ),
                        )
                      else if (_error != null)
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: 120,
                                  height: 34,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.gold,
                                      foregroundColor: AppColors.navy,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: _fetchReviews,
                                    child: const Text(
                                      'Coba Lagi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_stats != null && _stats!.totalReviews > 0) ...[
                        ReviewStatsSection(stats: _stats!, showPreviewCards: false),
                        const SizedBox(height: 16),
                        const Text(
                          'Semua Ulasan',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...(_stats!.reviews)
                            .map((review) => ReviewCardFull(review: review)),
                      ] else
                        const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              'Belum ada ulasan untuk kos ini.',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
