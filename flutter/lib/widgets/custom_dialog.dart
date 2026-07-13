import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onClose;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Prevent taps from passing through
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Main Dialog Box
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.only(
                    top: 50,
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF246DF1),
                      width: 6,
                    ),
                  ),
                  child: content,
                ),
                
                // Top Banner
                Positioned(
                  top: -24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD13B),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFB35522),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                
                // Close Button
                if (onClose != null)
                  Positioned(
                    top: -10,
                    right: 25,
                    child: GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF246DF1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1B55C0),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
