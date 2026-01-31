

import 'package:flutter/material.dart';

import '../../globals.dart';

class DropDown extends StatefulWidget {
  const DropDown({
    super.key,
    required this.label,
    required this.items,
    required this.onPress,
    this.itemHeight = 40,
    this.menuDecoration,
  });

  final String label;
  final List<String> items;
  final double itemHeight;
  final BoxDecoration? menuDecoration;
  final ValueChanged<String> onPress;

  @override
  State<DropDown> createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {
  double height = 0, width = 0, initX = 0, initY = 0;
  final GlobalKey actionKey = GlobalKey();
  OverlayEntry? dropdown;
  bool isOpen = false;
  bool selected = false;
  final ValueNotifier<int?> hoveredIdx = ValueNotifier<int?>(null);

  void findDropDownData() {
    final renderBox = actionKey.currentContext!.findRenderObject() as RenderBox;
    height = renderBox.size.height;
    width = renderBox.size.width;
    final offset = renderBox.localToGlobal(Offset.zero);
    initX = offset.dx;
    // keep dropdown on-screen horizontally
    final screenWidth = MediaQuery.of(context).size.width;
    if (initX + width > screenWidth) {
      initX = screenWidth - width - 8; // give 8px padding
    }
    initY = offset.dy;
  }

  void close() {
    if (isOpen) {
      dropdown!.remove();
      isOpen = false;
      setState(() {});
    }
  }

  OverlayEntry _createDropDown() {
    final maxVisible = widget.items.length > 4 ? 4 : widget.items.length;
    return OverlayEntry(builder: (context) {
      return GestureDetector(
        onTap: close,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: initX,
              top: initY + height + 5,
              width: width,
              height: widget.itemHeight * maxVisible,
              child: Material(
                color: Colors.transparent,
                child: ValueListenableBuilder<int?>(
                  valueListenable: hoveredIdx,
                  builder: (_, hovered, __) {
                    return Container(
                      decoration: widget.menuDecoration,
                      child: ListView.builder(
                        itemCount: widget.items.length,
                        itemBuilder: (context, i) {
                          final item = widget.items[i];
                          return MouseRegion(
                            onEnter: (_) => hoveredIdx.value = i,
                            onExit: (_) => hoveredIdx.value = null,
                            child: InkWell(
                              onTap: () {
                                widget.onPress(item);
                                selected = true;
                                close();
                              },
                              child: Container(
                                height: widget.itemHeight,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: (i == hovered)
                                      ? Pallet.inside3
                                      : Colors.transparent,
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    // mark selected if the label matches one of the items
    if (widget.items.contains(widget.label)) {
      selected = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: actionKey,
      onTap: () {
        if (isOpen) {
          close();
        } else {
          findDropDownData();
          dropdown = _createDropDown();
          Overlay.of(context).insert(dropdown!);
          isOpen = true;
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: Pallet.inside2,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Container(
              width: 4,
              height: 20,
              color: selected ? Colors.green : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
