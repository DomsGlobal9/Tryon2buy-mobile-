import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/animations/reveal_on_scroll.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../routes/app_router.dart';
import '../widgets/content_widgets.dart';

/// The website's About Us page, section for section.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        title: Text('About Us', style: AppTypography.display(size: 22)),
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
                  RichText(
                    text: TextSpan(
                      style: AppTypography.display(size: 38),
                      children: [
                        const TextSpan(text: 'Revolutionizing How The World Experiences '),
                        TextSpan(
                          text: 'Fashion.',
                          style: AppTypography.display(
                            size: 38,
                            color: AppColors.brandOrange,
                            style: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "We're a passionate team united by a common goal — to create meaningful solutions that bridge the gap between physical retail and digital commerce through unparalleled AI technology.",
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ContentCta(
                    label: 'Become a Merchant',
                    onTap: () => AppRouter.openSignIn(context, register: true),
                  ),
                  const SizedBox(height: 10),
                  ContentCta(
                    label: 'Book a Demo',
                    outlined: true,
                    onTap: () => showDemoDialog(context),
                  ),
                ],
              ),
            ),
          ),

          // ── Old way / solution / result ────────────────────────
          const SectionPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Badge(
                  icon: Icons.no_photography_outlined,
                  title: 'The Old Way',
                  text: 'Traditional fashion cataloging is slow, expensive, and heavily limited by physical constraints.',
                  background: AppColors.ink,
                  foreground: Colors.white,
                  muted: Color(0xFFA69C92),
                ),
                SizedBox(height: 12),
                _Badge(
                  icon: Icons.auto_fix_high_outlined,
                  title: 'The Solution',
                  text: 'Instant digital draping bypasses physical photo studios completely, reducing time-to-market by 90%.',
                  background: Colors.white,
                  foreground: AppColors.ink,
                  muted: AppColors.textSecondary,
                ),
                SizedBox(height: 12),
                _Badge(
                  icon: Icons.play_circle_outline,
                  title: 'The Result',
                  text: 'Zero photography costs. 100% photorealistic, studio-grade results in seconds.',
                  background: AppColors.brandOrange,
                  foreground: Colors.white,
                  muted: Colors.white,
                ),
              ],
            ),
          ),

          SectionPadding(
            child: RevealOnScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The Evolution of\nFashion E-Commerce.', style: AppTypography.display(size: 32)),
                  const SizedBox(height: 18),
                  const ContentParagraph(
                    'For decades, fashion boutiques and brands have relied on expensive, time-consuming photoshoots to showcase their new collections. Hiring models, renting studios, and waiting for post-production editing drains resources and slows down your time-to-market.',
                  ),
                  const ContentParagraph(
                    'At TryOn2Buy, we realized that the future of fashion commerce needed to be instant and effortless. We built a dual-engine platform designed specifically to solve this problem from both sides:',
                  ),
                  const SizedBox(height: 6),
                  const ContentBullet(
                    icon: Icons.no_photography_outlined,
                    title: 'Vendor-Side Digital Draping',
                    text: 'Completely avoid product photoshoots. Simply upload a basic flat lay photo of a saree, lehenga, or kurti from your inventory. Our AI instantly drapes it onto a professional virtual model, generating studio-grade catalog images in seconds.',
                  ),
                  const ContentBullet(
                    icon: Icons.people_outline,
                    title: 'Customer-Side Virtual Try-On',
                    text: 'Once your catalog is digitized, your shoppers can upload their own photos to instantly try on any garment, drastically increasing confidence and reducing return rates.',
                  ),
                ],
              ),
            ),
          ),

          // ── Core pillars ───────────────────────────────────────
          Container(
            color: AppColors.ink,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                Text('Our Core Pillars', style: AppTypography.display(size: 32, color: Colors.white)),
                const SizedBox(height: 24),
                const _Pillar(
                  icon: Icons.play_circle_outline,
                  title: 'Innovation First',
                  text: 'We continuously push the boundaries of generative AI to ensure our virtual try-ons are indistinguishable from real photography.',
                ),
                const SizedBox(height: 12),
                const _Pillar(
                  icon: Icons.shield_outlined,
                  title: 'Uncompromising Quality',
                  text: 'We believe that digital assets must match the luxury and craftsmanship of the physical garments they represent.',
                ),
                const SizedBox(height: 12),
                const _Pillar(
                  icon: Icons.people_outline,
                  title: 'Empowering Brands',
                  text: 'Our mission is to arm boutique owners and independent designers with enterprise-grade technology to compete globally.',
                ),
              ],
            ),
          ),

          // ── Technology ─────────────────────────────────────────
          SectionPadding(
            child: RevealOnScroll(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Driven by\nAdvanced AI.', style: AppTypography.display(size: 32)),
                  const SizedBox(height: 20),
                  const NumberedStep(
                    number: 1,
                    title: 'Identity Lock Technology',
                    text: "Our proprietary AI strictly preserves the customer's face, body type, and skin tone, ensuring an authentic and ethical try-on experience.",
                  ),
                  const NumberedStep(
                    number: 2,
                    title: 'Dynamic Draping Physics',
                    text: 'Unlike simple overlays, our system understands fabric weight, pleats, and gravity to drape garments exactly as they would fall in reality.',
                  ),
                  const NumberedStep(
                    number: 3,
                    title: 'Studio Lighting Emulation',
                    text: 'Automatically matches ambient lighting and generates realistic drop shadows to composite subjects seamlessly into any luxury environment.',
                  ),
                ],
              ),
            ),
          ),

          // ── Final CTA ──────────────────────────────────────────
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.favorite_border, color: AppColors.brandOrange, size: 28),
                const SizedBox(height: 16),
                Text('Join the Revolution.', textAlign: TextAlign.center, style: AppTypography.display(size: 32)),
                const SizedBox(height: 12),
                Text(
                  'Ready to transform how your customers experience your fashion catalog? Start your journey with TryOn2Buy today.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ContentCta(
                  label: 'Become a Merchant',
                  onTap: () => AppRouter.openSignIn(context, register: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () => launchUrl(Uri(scheme: 'mailto', path: 'info@tryon2buy.com')),
              child: Text('INFO@TRYON2BUY.COM', style: AppTypography.eyebrow(size: 12.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color background;
  final Color foreground;
  final Color muted;

  const _Badge({
    required this.icon,
    required this.title,
    required this.text,
    required this.background,
    required this.foreground,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 30, offset: const Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: background == AppColors.brandOrange ? Colors.white : AppColors.brandOrange),
          const SizedBox(height: 14),
          Text(title.toUpperCase(), style: AppTypography.eyebrow(size: 13, color: foreground, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(text, style: AppTypography.bodyMedium.copyWith(color: muted)),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _Pillar({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      color: const Color(0xFF2A2420),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.accentGold),
          const SizedBox(height: 16),
          Text(title.toUpperCase(), textAlign: TextAlign.center, style: AppTypography.eyebrow(size: 14, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: AppTypography.bodyMedium.copyWith(color: const Color(0xFFA69C92))),
        ],
      ),
    );
  }
}
