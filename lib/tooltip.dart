import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/event_manager.dart';

class MyTooltip extends StatefulWidget {
  final Widget child; // The widget the tooltip will wrap (e.g., an Icon)
  final Widget content; // The custom content to display in the popup
  final Color? arrowColor;
  final OverlayPortalController? overlayController;

  const MyTooltip({
    super.key,
    required this.child,
    required this.content,
    this.arrowColor,
    this.overlayController,
  });

  @override
  State<MyTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<MyTooltip> {
  OverlayPortalController _overlayController = OverlayPortalController();
  final _layerLink = LayerLink();
  bool _open = false;
  // GlobalMouseEvent? clickValue;

  @override
  void initState() {
    super.initState();

    if (widget.overlayController != null) {
      _overlayController = widget.overlayController as OverlayPortalController;
    }
  }

  Widget _buildOverlay(BuildContext context) {
    Color paintColor = Colors.white;
    if (widget.arrowColor != null) {
      paintColor = widget.arrowColor as Color;
    }

    return CompositedTransformFollower(
      link: _layerLink,
      offset: const Offset(0.0, 0.0),
      targetAnchor: Alignment.topCenter,
      child: Align(
        alignment: Alignment.topLeft,
        child: CustomPaint(
          painter: TooltipPainter(paintColor),
          child: widget.content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: () {
        globalEventNotifier.value = _overlayController;
        _overlayController.toggle();
        _open = !_open;
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: _buildOverlay,
          child: widget.child,
        ),
      ),
    );
  }
}

class TooltipPainter extends CustomPainter {
  final Color color;

  TooltipPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // The size of the arrow (beak)
    const double arrowHeight = 8.0;
    const double arrowWidth = 16.0;

    // Define the path for the background rectangle with a top-center arrow
    Path path = Path()
      // Start at the bottom-left corner of the main body
      ..moveTo(0, size.height)
      // Line up to the left side of the arrow base
      ..lineTo(0, size.height)
      // Draw the top point of the arrow
      ..lineTo(arrowWidth / 2, size.height + arrowHeight)
      // Line down to the right side of the arrow base
      ..lineTo(arrowWidth, size.height)
      ..close()
    ; // Close the path (back to the start)

    path = path.shift(Offset((size.width - arrowWidth) / 2, 0.0));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
