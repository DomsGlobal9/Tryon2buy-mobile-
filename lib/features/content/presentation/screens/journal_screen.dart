import 'package:flutter/material.dart';

import '../../../../core/animations/app_motion.dart';
import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/animations/pressable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../routes/app_router.dart';
import '../../data/site_content.dart';

/// "The TryOn2Buy Journal" — the website's `/blog` index.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Journal', style: AppTypography.display(size: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('The TryOn2Buy Journal', style: AppTypography.display(size: 36)),
          const SizedBox(height: 10),
          Text(
            'Insights on fashion physics, ecommerce strategy, and the future of virtual try-on for Indian ethnic wear.',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < SiteContent.journal.length; i++)
            FadeSlideIn(
              delay: AppMotion.staggerFor(i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PostCard(post: SiteContent.journal[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final JournalPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => Navigator.pushNamed(context, AppRouter.journalPost, arguments: post.slug),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.background,
                    child: RemoteImage(url: post.image, fallbackIcon: Icons.article_outlined),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(post.category.toUpperCase(), style: AppTypography.eyebrow(size: 11.5, color: AppColors.ink)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: AppTypography.marketing(size: 20, weight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 8),
                  Text(post.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.bodyMedium.copyWith(fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single post — `/blog/:slug`.
class JournalPostScreen extends StatelessWidget {
  final String slug;

  const JournalPostScreen({super.key, required this.slug});

  static const _gold = Color(0xFF7F5700);

  @override
  Widget build(BuildContext context) {
    final post = SiteContent.post(slug);
    if (post == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyStateView(
          icon: Icons.article_outlined,
          title: 'Post Not Found',
          message: 'This article may have moved.',
          actionLabel: 'Back to Journal',
          onAction: () => Navigator.maybePop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('Journal', style: AppTypography.display(size: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(post.category.toUpperCase(), textAlign: TextAlign.center, style: AppTypography.eyebrow(size: 12, color: _gold)),
          const SizedBox(height: 10),
          Text(post.title, textAlign: TextAlign.center, style: AppTypography.display(size: 34)),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12))],
              ),
              clipBehavior: Clip.antiAlias,
              child: RemoteImage(url: post.image, fallbackIcon: Icons.article_outlined),
            ),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < post.body.length; i++) _block(post.body[i], lead: i == 0),
        ],
      ),
    );
  }

  Widget _block(String line, {required bool lead}) {
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Text(line.substring(2), style: AppTypography.display(size: 28)),
      );
    }
    if (line.startsWith('> ')) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.only(left: 18, top: 6, bottom: 6),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: _gold, width: 4))),
        child: Text(
          '"${line.substring(2)}"',
          style: AppTypography.display(size: 22, style: FontStyle.italic),
        ),
      );
    }
    if (line.startsWith('- ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.circle, size: 6, color: _gold),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(line.substring(2), style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        line,
        style: lead
            ? AppTypography.bodyLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textSecondary)
            : AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
