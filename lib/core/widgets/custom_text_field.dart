import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Color? fillColor;
  final Color? labelColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? borderColor;
  final Color? focusedBorderColor;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.fillColor,
    this.labelColor,
    this.textColor,
    this.hintColor,
    this.borderColor,
    this.focusedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? AppColors.border;
    final effectiveFocusedBorder = focusedBorderColor ?? AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            fontSize: 14,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: AppTypography.bodyLarge.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: hintColor != null ? TextStyle(color: hintColor) : null,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: effectiveBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: effectiveBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: effectiveFocusedBorder, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
