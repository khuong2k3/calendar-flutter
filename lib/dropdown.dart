import 'package:flutter/material.dart';
import 'package:flutter_app/sizedwidget.dart';

class MyDropdown extends StatefulWidget {
  Widget content;
  Widget child;
  OverlayPortalController? controller;
  Color? arrowColor;


  MyDropdown({
    super.key,
    required this.content,
    required this.child,
    this.controller,
    this.arrowColor,
  });

  @override
  State<StatefulWidget> createState() => _Dropdown();
}

class _Dropdown extends State<MyDropdown> {
  late OverlayPortalController _overlayCtrl;
  final _layerLink = LayerLink();

  Size _size = Size(0, 0);
  Size _sizeContent = Size(0, 0);

  @override
  void initState() {
    super.initState();

    if (widget.controller != null) {
      _overlayCtrl = widget.controller as OverlayPortalController;
    } else {
      _overlayCtrl = OverlayPortalController();
    }
  }

  Widget _dropdownBuilder(BuildContext context) {
    return CompositedTransformFollower(
      offset: Offset(
        (_size.width - _sizeContent.width) / 2,
        _size.height + arrowHeight,
      ),
      link: _layerLink,
      child: Align(
        alignment: Alignment.topLeft,
        child: CustomPaint(
          painter: TooltipPainter(
            color: widget.arrowColor == null ? Colors.black87 : widget.arrowColor as Color, 
            alignment: Alignment.topLeft,
            offset: Offset(0.0, 0.0),
          ),
          child: Sizedwidget(
            onSize: (size) {
              setState(() {
                _sizeContent = size;
              });
            },
            child: widget.content,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayCtrl,
        overlayChildBuilder: _dropdownBuilder,
        child: Listener(
          onPointerDown: (_) {
            _overlayCtrl.toggle();
          },
          child: Sizedwidget(
            onSize: (size) {
              _size = size;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class SelectionList extends StatelessWidget {
  final List<DropdownMenuItem> items;
  final void Function(dynamic) onSelected;

  SelectionList({required this.onSelected, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        spacing: 5,
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return InkWell(
            focusColor: Colors.blue,
            onTap: () {
              onSelected(item.value);
              if (item.onTap != null) {
                (item.onTap as void Function())();
              }
            },
            child: item.child,
          );
        }).toList(),
      ),
    );
  }
}

const double arrowHeight = 8.0;
const double arrowWidth = 16.0;

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
