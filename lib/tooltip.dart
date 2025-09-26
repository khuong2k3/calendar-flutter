import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/event_manager.dart';

// class MyTooltip extends StatefulWidget {
//   final Widget child; // The widget the tooltip will wrap (e.g., an Icon)
//   final Widget content; // The custom content to display in the popup
//   final Color? arrowColor;
//   final OverlayPortalController? overlayController;
//
//   const MyTooltip({
//     super.key,
//     required this.child,
//     required this.content,
//     this.arrowColor,
//     this.overlayController,
//   });
//
//   @override
//   State<MyTooltip> createState() => _CustomTooltipState();
// }

// class _CustomTooltipState extends State<MyTooltip> {
//   OverlayPortalController _overlayController = OverlayPortalController();
//   final _layerLink = LayerLink();
//   bool _open = false;
//   // GlobalMouseEvent? clickValue;
//
//   @override
//   void initState() {
//     super.initState();
//
//     if (widget.overlayController != null) {
//       _overlayController = widget.overlayController as OverlayPortalController;
//     }
//   }
//
//   Widget _buildOverlay(BuildContext context) {
//     Color paintColor = Colors.white;
//     if (widget.arrowColor != null) {
//       paintColor = widget.arrowColor as Color;
//     }
//
//     return CompositedTransformFollower(
//       link: _layerLink,
//       offset: const Offset(0.0, 0.0),
//       targetAnchor: Alignment.topCenter,
//       child: Align(
//         alignment: Alignment.topLeft,
//         child: CustomPaint(
//           painter: TooltipPainter(paintColor),
//           child: widget.content,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return InkWell(
//       onTap: () {
//         globalEventNotifier.value = _overlayController;
//         _overlayController.toggle();
//         _open = !_open;
//       },
//       child: CompositedTransformTarget(
//         link: _layerLink,
//         child: OverlayPortal(
//           controller: _overlayController,
//           overlayChildBuilder: _buildOverlay,
//           child: widget.child,
//         ),
//       ),
//     );
//   }
// }

const double arrowHeight = 8.0;
const double arrowWidth = 16.0;

class TooltipWrapper extends StatefulWidget {
  final Widget child;
  final Color paintColor;
  final Alignment alignment;
  final LayerLink layerLink;
  final Offset globalOffset;
  final Size? boundingBox;

  const TooltipWrapper({
    required this.child,
    required this.layerLink,
    required this.globalOffset,
    this.boundingBox,
    this.paintColor = Colors.white,
    this.alignment = Alignment.topLeft,
  });

  @override
  State<StatefulWidget> createState() => _TooltipWrapper();
}

class _TooltipWrapper extends State<TooltipWrapper> {
  Size? _size;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_key.currentContext?.size != null) {
        setState(() {
          _size = _key.currentContext?.size;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Offset newOffset = widget.globalOffset;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (widget.alignment.y < 0) {
      newOffset = newOffset.translate(0.0, arrowHeight);
      if (_size != null) {
        Size size = _size as Size;
        newOffset = newOffset.translate(-size.width / 2, 0.0);

        if (widget.boundingBox != null) {
          Size boundingBox = widget.boundingBox as Size;

          double rightX = newOffset.dx + size.width;
          if (rightX > boundingBox.width) {
            offsetX = boundingBox.width - rightX;
          }
          if (newOffset.dy + size.height > boundingBox.height) {
            offsetY = -size.height;
          }
          newOffset = newOffset.translate(offsetX, offsetY);
        }
      }
    }

    return CompositedTransformFollower(
      link: widget.layerLink,
      offset: newOffset,
      targetAnchor: Alignment.topLeft,
      child: Align(
        alignment: Alignment.topLeft,
        child: CustomPaint(
          key: _key,
          painter: TooltipPainter(
            color: widget.paintColor,
            alignment: widget.alignment,
            offset: Offset(offsetX, offsetY),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class TooltipPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;
  final Offset offset;

  const TooltipPainter({
    required this.color,
    required this.alignment,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // print(offset);
    if (alignment.y < 0) {}
    // Define the path for the background rectangle with a top-center arrow
    Path path = offset.dy < 0
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(0, size.height)
            ..lineTo(arrowWidth / 2, size.height + arrowHeight)
            ..lineTo(arrowWidth, size.height)
            ..close())
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(0, 0)
            ..lineTo(arrowWidth / 2, -arrowHeight)
            ..lineTo(arrowWidth, 0)
            ..close());

    path = path.shift(Offset((size.width - arrowWidth) * 0.5 - offset.dx, 0.0));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
