import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/scanned_garment.dart';

/// Bottom sheet prompting the shopper to confirm which colour they are holding.
///
/// Parity with the web frontend's colour variant modal (`ClientTryon.jsx`).
class ColorVariantSheet extends StatefulWidget {
  final List<GarmentColour> colours;
  final String? initialCode;
  final String garmentTitle;

  const ColorVariantSheet({
    super.key,
    required this.colours,
    this.initialCode,
    required this.garmentTitle,
  });

  /// Displays the sheet and returns the chosen [GarmentColour], or null if dismissed.
  static Future<GarmentColour?> show(
    BuildContext context, {
    required List<GarmentColour> colours,
    String? initialCode,
    required String garmentTitle,
  }) {
    return showModalBottomSheet<GarmentColour>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ColorVariantSheet(
        colours: colours,
        initialCode: initialCode,
        garmentTitle: garmentTitle,
      ),
    );
  }

  @override
  State<ColorVariantSheet> createState() => _ColorVariantSheetState();
}

class _ColorVariantSheetState extends State<ColorVariantSheet> {
  late String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCode ??
        (widget.colours.isNotEmpty ? widget.colours.first.code : null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            'Which colour are you trying?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.garmentTitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // Colours Grid / List
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.colours.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = widget.colours[index];
                final isSelected = c.code == _selectedCode;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCode = c.code;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.brandOrange.withValues(alpha: 0.08)
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandOrange
                            : AppColors.borderLight,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Colour thumbnail or placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: AppColors.borderLight,
                            child: (c.imageUrl != null && c.imageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: c.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.palette_outlined,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                  )
                                : const Icon(
                                    Icons.palette_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Colour name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name.isNotEmpty ? c.name : c.code,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.brandOrange
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (c.name.isNotEmpty && c.code.isNotEmpty && c.name != c.code)
                                Text(
                                  'Code: ${c.code}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Check radio icon
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brandOrange
                                  : AppColors.border,
                              width: 2,
                            ),
                            color: isSelected
                                ? AppColors.brandOrange
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Button
          ElevatedButton(
            onPressed: () {
              final chosen = widget.colours.firstWhere(
                (c) => c.code == _selectedCode,
                orElse: () => widget.colours.first,
              );
              Navigator.of(context).pop(chosen);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Select This Colour',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
