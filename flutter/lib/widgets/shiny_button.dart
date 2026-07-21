import 'package:flutter/material.dart';
import '../utils/sound_service.dart';

class ShinyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final double height;
  final double width;

  const ShinyButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.gradientColors,
    required this.borderColor,
    this.shadowColor = const Color(0x33000000),
    this.height = 60.0,
    this.width = double.infinity,
  });

  @override
  State<ShinyButton> createState() => _ShinyButtonState();
}

class _ShinyButtonState extends State<ShinyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        SoundService.instance.playTouch();
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: EdgeInsets.only(top: _isPressed ? 4.0 : 0.0),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.borderColor,
            width: 3,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: widget.shadowColor,
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            children: [
              // Base Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.gradientColors,
                  ),
                ),
              ),
              // Content
              Center(
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
