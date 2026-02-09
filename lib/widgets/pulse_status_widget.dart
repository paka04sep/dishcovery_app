import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/utils/time_utils.dart'; // Adjust path if needed

class PulseStatusWidget extends StatefulWidget {
  final RestaurantStatus status;
  final double size;

  const PulseStatusWidget({
    super.key,
    required this.status,
    this.size = 14, // default
  });

  @override
  State<PulseStatusWidget> createState() => _PulseStatusWidgetState();
}

class _PulseStatusWidgetState extends State<PulseStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _checkAnimation();
  }

  @override
  void didUpdateWidget(covariant PulseStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _checkAnimation();
    }
  }

  void _checkAnimation() {
    if (widget.status == RestaurantStatus.open) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (widget.status) {
      case RestaurantStatus.open:
        color = Colors.green;
        text = 'เปิด';
        break;
      case RestaurantStatus.closingSoon:
        color = Colors.amber;
        text = 'ใกล้ปิด';
        break;
      case RestaurantStatus.closed:
        color = Colors.red;
        text = 'ปิด';
        break;
    }

    final dotSize = widget.size;
    final fontSize = widget.size;
    final hPad = widget.size;
    final vPad = widget.size * 0.5;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(widget.size * 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (widget.status == RestaurantStatus.open)
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          SizedBox(width: widget.size * 0.6),
          Text(
            text,
            style: AppTextStyles.restaurantInDetails.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
