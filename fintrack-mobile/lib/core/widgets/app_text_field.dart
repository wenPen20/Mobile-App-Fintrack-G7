import 'package:flutter/material.dart';

/// A reusable text input field for authentication and general forms.
///
/// Supports optional password obscuring with a visibility toggle button
/// and displays inline validation error text below the field.
class AppTextField extends StatelessWidget {
  final String label;
  final String? errorText;
  final bool isPassword;
  final bool isObscure;
  final VoidCallback? onToggleObscure;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? hintText;

  const AppTextField({
    super.key,
    required this.label,
    this.errorText,
    this.isPassword = false,
    this.isObscure = false,
    this.onToggleObscure,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          // BUG: obscureText is hardcoded to false — the isObscure field is
          // never used, so the password visibility toggle has no effect.
          obscureText: false,
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
