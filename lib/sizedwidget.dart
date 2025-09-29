import 'package:flutter/material.dart';

class Sizedwidget extends StatefulWidget {
  final Widget? child;
  final void Function(Size) onSize;

  const Sizedwidget({super.key, this.child, required this.onSize});

  @override
  State<StatefulWidget> createState() => _Sizedwidget();
}

class _Sizedwidget extends State<Sizedwidget> {
  Size? _size;
  final GlobalKey _key = GlobalKey();

  void _setSize() {
    RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      if (renderBox.size != _size) {
        _size = renderBox.size;

        widget.onSize(_size as Size);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPersistentFrameCallback((_) {
      _setSize();
      WidgetsBinding.instance.addPersistentFrameCallback((_) {
        _setSize();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(key: _key, child: widget.child);
  }
}
