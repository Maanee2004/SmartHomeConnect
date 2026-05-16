import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hint,
    this.obscure = false,
    required this.icon,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.semanticsLabel,
  });

  final String hint;
  final bool obscure;
  final IconData icon;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final String? semanticsLabel;

  static const double _radius = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textSecondary),
        prefixIcon: Icon(icon, color: c.textSecondary),
        suffixIcon: suffix ??
            (obscure
                ? Icon(Icons.visibility_off, color: c.textSecondary)
                : null),
        filled: true,
        fillColor: c.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
    if (semanticsLabel == null) return field;
    return Semantics(
      textField: true,
      label: semanticsLabel,
      child: field,
    );
  }
}
