import 'package:flutter/material.dart';

/// Full-width call-to-action button with a built-in loading state.
///
/// When [enabled] is false the button is greyed out and non-tappable —
/// used to keep the submit button disabled until a form is valid.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (enabled && !isLoading) ? onPressed : null,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
