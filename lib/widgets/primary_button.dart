import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool gradient;
  final bool expanded;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gradient = false,
    this.expanded = true,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onPressed == null;

    final Widget child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(AppColors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          );

    if (gradient) {
      return SizedBox(
        width: expanded ? double.infinity : null,
        height: 52,
        child: Opacity(
          opacity: disabled && !loading ? 0.5 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradient,
              borderRadius: BorderRadius.circular(AppColors.rButton),
            ),
            child: ElevatedButton(
              onPressed: disabled ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColors.rButton),
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: expanded ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
    );
  }
}
