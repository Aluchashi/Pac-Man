import 'package:flutter/material.dart';

class DPad extends StatelessWidget {
  const DPad({
    super.key,
    this.onUp,
    this.onDown,
    this.onLeft,
    this.onRight,
    this.onUpRelease,
    this.onDownRelease,
    this.onLeftRelease,
    this.onRightRelease,
    required this.size,
  });

  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final VoidCallback? onUpRelease;
  final VoidCallback? onDownRelease;
  final VoidCallback? onLeftRelease;
  final VoidCallback? onRightRelease;

  final double size;

  @override
  Widget build(BuildContext context) {
    final double btnSize = size * 0.35;
    final double center = size / 2 - btnSize / 2;
    final double separation = size * 0.30;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: center - separation,
            left: center,
            child: _ArcadeButton(
              size: btnSize,
              color: const Color(0xFFE03232), // red
              icon: Icons.change_history_rounded,
              rotation: 0,
              onTap: onUp,
              onRelease: onUpRelease,
            ),
          ),

          Positioned(
            top: center + separation,
            left: center,
            child: _ArcadeButton(
              size: btnSize,
              color: const Color(0xFFD4A017), // amber/gold
              icon: Icons.change_history_rounded,
              rotation: 3.14159,
              onTap: onDown,
            ),
          ),

          Positioned(
            top: center,
            left: center - separation,
            child: _ArcadeButton(
              size: btnSize,
              color: const Color(0xFF2A5FC4),
              icon: Icons.change_history_rounded,
              rotation: -1.5708,
              onTap: onLeft,
            ),
          ),

          Positioned(
            top: center,
            left: center + separation,
            child: _ArcadeButton(
              size: btnSize,
              color: const Color(0xFF2E9E3E),
              icon: Icons.change_history_rounded,
              rotation: 1.5708,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeButton extends StatefulWidget {
  const _ArcadeButton({
    required this.size,
    required this.color,
    required this.icon,
    required this.rotation,
    this.onTap,
    this.onRelease,
  });

  final double size;
  final Color color;
  final IconData icon;
  final double rotation;
  final VoidCallback? onTap;
  final VoidCallback? onRelease;

  @override
  State<_ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<_ArcadeButton> {
  bool _pressed = false;
  static const double _sinkAmount = 4.0;

  @override
  Widget build(BuildContext context) {
    final Color shadowColor = HSLColor.fromColor(widget.color)
        .withLightness(
          (HSLColor.fromColor(widget.color).lightness - 0.22).clamp(0.0, 1.0),
        )
        .toColor();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        widget.onTap?.call();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onRelease?.call();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        widget.onRelease?.call();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size + _sinkAmount,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 0,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: shadowColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOut,
              bottom: _pressed ? 0 : _sinkAmount,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: Transform.rotate(
                  angle: widget.rotation,
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.42,
                    color: shadowColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
