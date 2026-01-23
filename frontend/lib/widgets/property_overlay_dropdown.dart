import 'dart:ui';
import 'package:flutter/material.dart';
import '../utilities/pallet.dart';

class PropertyOverlayDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T> onChanged;
  final String label;
  final bool showLabel;
  final String Function(T)? itemLabelBuilder;

  const PropertyOverlayDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label = '',
    this.showLabel = true,
    this.itemLabelBuilder,
  });

  @override
  State<PropertyOverlayDropdown<T>> createState() =>
      _PropertyOverlayDropdownState<T>();
}

class _PropertyOverlayDropdownState<T>
    extends State<PropertyOverlayDropdown<T>> {
  double height = 0, width = 0, initX = 0, initY = 0;
  GlobalKey actionKey = GlobalKey();
  OverlayEntry? dropdown;
  bool isOpen = false;
  final ValueNotifier<int?> hoveredIdx = ValueNotifier<int?>(null);

  void findDropDownData() {
    RenderBox renderBox =
        actionKey.currentContext!.findRenderObject() as RenderBox;
    height = renderBox.size.height;
    width = renderBox.size.width;
    Offset offset = renderBox.localToGlobal(Offset.zero);
    initX = offset.dx;
    initY = offset.dy;
  }

  void close() {
    if (isOpen) {
      dropdown!.remove();
      isOpen = false;
      if (mounted) setState(() {});
    }
  }

  OverlayEntry _createDropDown() {
    return OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final screenWidth = MediaQuery.of(context).size.width;

            // Allow width to be at least the button width, but maybe wider if needed
            // For font weight, it's usually small, so button width is probably fine.
            // But let's set a min width.
            final dropdownWidth = width < 120 ? 120.0 : width;

            // Calculate horizontal position
            double leftPos = initX;
            if (leftPos + dropdownWidth > screenWidth - 10) {
              double triggerRight = initX + width;
              leftPos = triggerRight - dropdownWidth;

              if (leftPos + dropdownWidth > screenWidth - 10) {
                leftPos = screenWidth - dropdownWidth - 10;
              }
            }
            if (leftPos < 10) leftPos = 10;

            final itemHeight = 35.0;
            final maxItems = 6;
            final listHeight =
                itemHeight *
                (widget.items.length > maxItems
                    ? maxItems
                    : widget.items.length);
            // Add some padding
            // Add some padding
            // final totalHeight = listHeight + 10;

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    close();
                  },
                  child: Container(
                    color: Colors.transparent,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
                Positioned(
                  left: leftPos,
                  width: dropdownWidth,
                  top: initY + height + 5,
                  child: Material(
                    elevation: 60,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Pallet.inside1.withOpacity(0.9),
                        border: Border.all(color: Pallet.inside2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: ValueListenableBuilder<int?>(
                            valueListenable: hoveredIdx,
                            builder: (context, _hoveredIdx, child) {
                              return Container(
                                constraints: BoxConstraints(maxHeight: 250),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: widget.items.length,
                                  itemBuilder: (context, i) {
                                    final item = widget.items[i];
                                    final itemLabel =
                                        widget.itemLabelBuilder != null
                                        ? widget.itemLabelBuilder!(item)
                                        : item.toString();

                                    return MouseRegion(
                                      onEnter: (details) =>
                                          hoveredIdx.value = i,
                                      onExit: (details) =>
                                          hoveredIdx.value = null,
                                      child: InkWell(
                                        onTap: () {
                                          widget.onChanged(item);
                                          close();
                                        },
                                        child: Container(
                                          height: itemHeight,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (i == _hoveredIdx ||
                                                    item == widget.value)
                                                ? Pallet.inside3.withOpacity(
                                                    0.5,
                                                  )
                                                : Colors.transparent,
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  itemLabel,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Pallet.font2,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (item == widget.value)
                                                Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Pallet.font1,
                                                ),
                                            ],
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
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.itemLabelBuilder != null
        ? widget.itemLabelBuilder!(widget.value)
        : widget.value.toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel && widget.label.isNotEmpty)
          SizedBox(
            width: 80,
            child: Text(
              "${widget.label}:",
              style: TextStyle(fontSize: 13, color: Pallet.font1),
            ),
          ),
        if (widget.showLabel && widget.label.isNotEmpty)
          const SizedBox(width: 5),

        Expanded(
          child: InkWell(
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
              key: actionKey,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: Pallet.inside2,
                borderRadius: BorderRadius.circular(5),
                border: isOpen ? Border.all(color: Pallet.inside3) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      displayValue,
                      style: TextStyle(fontSize: 12, color: Pallet.font2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_sharp,
                    color: Pallet.font3,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
