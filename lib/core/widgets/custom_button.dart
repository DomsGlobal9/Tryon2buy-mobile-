import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height = 50,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isSecondary ? AppColors.surface : AppColors.primary);
    final fgColor = foregroundColor ?? (isSecondary ? AppColors.primary : AppColors.textWhite);
    final borderSide = borderColor != null
        ? BorderSide(color: borderColor!, width: 1.5)
        : (isSecondary
            ? const BorderSide(color: AppColors.border, width: 1.5)
            : BorderSide.none);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fgColor),
                    const SizedBox(width: 8),
                  ],
                  // Website buttons are set in uppercase, tracked Merriweather.
                  Text(
                    text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTypography.cta(color: fgColor),
                  ),
                ],
              ),
      ),
    );
  }
}
