import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../models/auth_session.dart';
import '../providers/branch_provider.dart';

class AdminBranchBadge extends StatefulWidget {
  const AdminBranchBadge({super.key});

  @override
  State<AdminBranchBadge> createState() => _AdminBranchBadgeState();
}

class _AdminBranchBadgeState extends State<AdminBranchBadge> {
  bool _loading = false;
  String? _error;

  int? get _branchId => AuthSessionStore.instance.user?.branchId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchBranch();
    });
  }

  Future<void> _fetchBranch() async {
    final branchId = _branchId;
    if (branchId == null || branchId <= 0) return;
    if (context.read<BranchProvider>().detailFor(branchId) != null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<BranchProvider>().fetchBranch(branchId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Cabang admin tidak bisa dimuat.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchId = _branchId;
    final branch = branchId == null
        ? null
        : context.watch<BranchProvider>().detailFor(branchId);
    final title = branch == null
        ? branchId == null
              ? 'Admin belum terhubung cabang'
              : 'Cabang ID $branchId'
        : branch.name;
    final subtitle = branch == null
        ? _error ?? (_loading ? 'Memuat detail cabang...' : 'Data cabang admin')
        : branch.address;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: branchId == null
            ? Colors.red.withValues(alpha: .1)
            : AppColors.navy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: branchId == null ? Colors.red : AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Icon(
              branchId == null
                  ? Icons.warning_rounded
                  : Icons.apartment_rounded,
              color: AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cabang Admin',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: branchId == null ? Colors.red : AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: branchId == null
                        ? Colors.red.withValues(alpha: .82)
                        : AppColors.white.withValues(alpha: .82),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
        ],
      ),
    );
  }
}
