import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/animations/pressable.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Swipeable promo cards with a dot indicator, the mobile stand-in for the
/// website's split hero. Each slide is one full-bleed image with a short
/// headline and a single pill CTA, so it reads at a glance while scrolling.
class HomeHeroCarousel extends StatefulWidget {
  final VoidCallback onTryOn;
  final VoidCallback onMerchant;

  const HomeHeroCarousel({
    super.key,
    required this.onTryOn,
    required this.onMerchant,
  });

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  /// Slightly under 1 so the next card peeks in from the edge, which is the
  /// cue that this row swipes.
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  late final List<_HeroSlide> _slides = [
    _HeroSlide(
      asset: 'assets/images/landingsaree.png',
      eyebrow: 'VIRTUAL TRY-ON',
      title: 'See it on you\nbefore you buy',
      cta: 'Start Try-On',
      onTap: widget.onTryOn,
    ),
    _HeroSlide(
      asset: 'assets/images/hero_video_poster.jpg',
      eyebrow: 'STUDIO GRADE',
      title: 'Editorial looks,\nno photoshoot',
      cta: 'Browse Looks',
      onTap: widget.onTryOn,
    ),
    _HeroSlide(
      asset: 'assets/images/tryon_models.png',
      eyebrow: 'FOR BOUTIQUES',
      title: 'Digitize your\ncatalog in minutes',
      cta: 'Merchant Portal',
      onTap: widget.onMerchant,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              // Left padding on the first card lines it up with the page
              // gutter; every card keeps a right gap so the peek has air.
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 20 : 6, right: 6),
                child: _HeroCard(slide: _slides[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: active ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? AppColors.brandOrange : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeroSlide {
  final String asset;
  final String eyebrow;
  final String title;
  final String cta;
  final VoidCallback onTap;

  const _HeroSlide({
    required this.asset,
    required this.eyebrow,
    required this.title,
    required this.cta,
    required this.onTap,
  });
}

class _HeroCard extends StatelessWidget {
  final _HeroSlide slide;

  const _HeroCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    // `cacheWidth` caps the decoded bitmap. These are catalogue-sized PNGs
    // shown in a card a few hundred points wide, and the carousel builds all
    // of them during the first home frame; decoding at full size is the
    // difference between a smooth launch and a visible stall.
    final Widget image = Image.asset(
      slide.asset,
      fit: BoxFit.cover,
      cacheWidth: 1000,
      filterQuality: FilterQuality.medium,
    );

    return Pressable(
      onTap: slide.onTap,
      pressedScale: 0.98,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            // Bottom-weighted scrim so white text stays legible over any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.25, 1.0],
                  colors: [Colors.transparent, Color(0xCC1A1410)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    slide.eyebrow,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: AppColors.brandOrange,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    slide.title,
                    style: GoogleFonts.ebGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      height: 1.05,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slide.cta,
                          style: AppTypography.buttonText.copyWith(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 15, color: AppColors.textPrimary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
