import 'package:flutter/material.dart';

/// Button widget có tích hợp loading state
/// - Hiển thị CircularProgressIndicator khi đang loading
/// - Disable button khi loading
/// - Màu cyan chuyên nghiệp
class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? loadingColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;
  final double fontSize;
  final FontWeight fontWeight;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.loadingColor,
    this.width,
    this.height = 50,
    this.borderRadius = 12,
    this.padding,
    this.icon,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? const Color(0xFF00BCD4); // Cyan
    final txtColor = textColor ?? Colors.white;
    final loadColor = loadingColor ?? Colors.white;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          disabledBackgroundColor: bgColor.withOpacity(0.6),
          disabledForegroundColor: txtColor.withOpacity(0.7),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(loadColor),
                ),
              )
            : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
              ),
      ),
    );
  }
}

/// Outlined loading button
class LoadingOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? borderColor;
  final Color? textColor;
  final Color? loadingColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Widget? icon;

  const LoadingOutlineButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.borderColor,
    this.textColor,
    this.loadingColor,
    this.width,
    this.height = 50,
    this.borderRadius = 12,
    this.padding,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = borderColor ?? const Color(0xFF00BCD4);
    final tColor = textColor ?? const Color(0xFF00BCD4);
    final lColor = loadingColor ?? const Color(0xFF00BCD4);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: tColor,
          side: BorderSide(color: bColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
          disabledForegroundColor: tColor.withOpacity(0.5),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(lColor),
                ),
              )
            : icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// Text button with loading state
class LoadingTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? textColor;
  final Color? loadingColor;
  final Widget? icon;

  const LoadingTextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.textColor,
    this.loadingColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tColor = textColor ?? const Color(0xFF00BCD4);
    final lColor = loadingColor ?? const Color(0xFF00BCD4);

    return TextButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(lColor),
              ),
            )
          : icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon!,
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: tColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Text(
              text,
              style: TextStyle(
                color: tColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Icon button with loading state
class LoadingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? loadingColor;
  final double size;
  final String? tooltip;

  const LoadingIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.loadingColor,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? const Color(0xFF00BCD4);
    final lColor = loadingColor ?? const Color(0xFF00BCD4);

    return IconButton(
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
      icon: isLoading
          ? SizedBox(
              height: size * 0.8,
              width: size * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(lColor),
              ),
            )
          : Icon(icon, size: size, color: iconColor),
    );
  }
}
