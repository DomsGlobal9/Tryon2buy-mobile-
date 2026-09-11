import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'home_section_header.dart';

/// Three-step explainer in a single card. The website's 2×2 marketing grid is
/// collapsed into a compact list, which is how a native app would onboard.
class HowItWorksStrip extends StatelessWidget {
  const HowItWorksStrip({super.key});

  static const _steps = <_Step>[
    _Step(
      icon: Icons.checkroom_outlined,
      title: 'Pick an outfit',
      body: 'Choose any saree, lehenga or kurti from the catalog.',
    ),
    _Step(
      icon: Icons.add_a_photo_outlined,
      title: 'Add a selfie',
      body: 'Snap a photo or use one from your gallery.',
    ),
    _Step(
      icon: Icons.auto_awesome_outlined,
      title: 'See it on you',
      body: 'Get a studio-quality try-on in seconds, then save it to My Looks.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'How it works'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _steps.length; i++) ...[
                  _StepRow(index: i + 1, step: _steps[i]),
                  if (i < _steps.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Step {
  final IconData icon;
  final String title;
  final String body;

  const _Step({required this.icon, required this.title, required this.body});
}

class _StepRow extends StatelessWidget {
  final int index;
  final _Step step;

  const _StepRow({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: index.isOdd ? AppColors.primary : AppColors.brandOrange,
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${step.title}',
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  step.body,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
