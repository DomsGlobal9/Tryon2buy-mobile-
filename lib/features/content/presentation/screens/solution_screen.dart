import 'package:flutter/material.dart';

import '../../../../core/animations/reveal_on_scroll.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../data/site_content.dart';

/// One of the five "Solutions" pages (Saree, Lehenga, Anarkali, Sharara,
/// Kurti), laid out like the website's `CategoryLayout`.
class SolutionScreen extends StatelessWidget {
  final String solutionKey;

  const SolutionScreen({super.key, required this.solutionKey});

  static const _gold = Color(0xFF7F5700);

  @override
  Widget build(BuildContext context) {
    final page = SiteContent.solution(solutionKey);
    if (page == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyStateView(
          icon: Icons.search_off_rounded,
          title: 'Page not found',
          message: 'There is no solution page called "$solutionKey".',
          actionLabel: 'Go back',
          onAction: () => Navigator.maybePop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text(page.navName, style: AppTypography.display(size: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Hero ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: RevealOnScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(page.title, style: AppTypography.display(size: 36)),
                  Text(
                    page.tagline,
                    style: AppTypography.display(size: 36, color: AppColors.textMuted, style: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Text(page.subtitle, style: AppTypography.marketing(size: 18, weight: FontWeight.w700, color: _gold)),
                  const SizedBox(height: 14),
                  Text(page.description, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRouter.vendorLogin),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text('START GENERATING', style: AppTypography.cta(size: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: RemoteImage(url: page.heroImage, fallbackIcon: Icons.checkroom),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Problem / Solution ─────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('The Problem', style: AppTypography.display(size: 28, color: AppColors.ink.withValues(alpha: 0.6))),
                const SizedBox(height: 10),
                Text(page.problemTitle, style: AppTypography.marketing(size: 22, weight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 10),
                Text(page.problemText, style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('The Solution', style: AppTypography.display(size: 28, color: _gold)),
                      const SizedBox(height: 10),
                      Text(page.solutionTitle, style: AppTypography.marketing(size: 22, weight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 22),
                      for (final (title, desc) in page.features)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 22, color: _gold),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: AppTypography.marketing(size: 15, weight: FontWeight.w700, color: AppColors.ink)),
                                    const SizedBox(height: 4),
                                    Text(desc, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Impact ─────────────────────────────────────────────
          Container(
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Text('Real-World Impact', style: AppTypography.display(size: 32, color: Colors.white)),
                const SizedBox(height: 24),
                for (final (metric, desc) in page.impact)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(metric, style: AppTypography.marketing(size: 34, weight: FontWeight.w800, color: _gold)),
                        const SizedBox(height: 8),
                        Text(desc, textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Index of the five solutions — the website's "Solutions" menu.
class SolutionsIndexScreen extends StatelessWidget {
  const SolutionsIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Solutions', style: AppTypography.display(size: 22)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: SiteContent.solutions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final s = SiteContent.solutions[i];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, AppRouter.solution, arguments: s.key),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.navName.toUpperCase(), style: AppTypography.cta(size: 11, color: AppColors.ink, letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text(s.navDesc, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
