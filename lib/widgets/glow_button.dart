import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';

/// Bouton principal : remplissage sage, léger dégradé vertical, ombre neutre (pas de glow néon).
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;

  static final Color _top = Color.lerp(primaryColor, Colors.white, 0.07)!;
  static final Color _bottom = Color.lerp(primaryColor, Colors.black, 0.12)!;

  @override
  Widget build(BuildContext context) {
    final busy = loading || !enabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_top, _bottom],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF0D1117),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: const TextStyle(
                          color: Color(0xFF0D1117),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: Color(0xFF0D1117).withValues(alpha: enabled ? 1 : 0.45),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
