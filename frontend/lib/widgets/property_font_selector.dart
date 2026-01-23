import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utilities/pallet.dart';

class PropertyFontSelector extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool showLabel;

  const PropertyFontSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showLabel = true,
  });

  @override
  State<PropertyFontSelector> createState() => _PropertyFontSelectorState();
}

class _PropertyFontSelectorState extends State<PropertyFontSelector> {
  double height = 0, width = 0, initX = 0, initY = 0;
  GlobalKey actionKey = GlobalKey();
  OverlayEntry? dropdown;
  bool isOpen = false;
  final ValueNotifier<int?> hoveredIdx = ValueNotifier<int?>(null);
  final TextEditingController searchController = TextEditingController();
  final List<String> allFonts = GoogleFonts.asMap().keys.toList();
  List<String> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = allFonts;
  }

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
      searchController.clear();
      filteredItems = allFonts;
      if (mounted) setState(() {});
    }
  }

  OverlayEntry _createDropDown() {
    return OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final dropdownWidth = 250.0;

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
                  width: dropdownWidth, // Wider overlay
                  top: initY + height + 5,
                  child: Material(
                    elevation: 60,
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Pallet.inside1.withOpacity(
                          0.9,
                        ), // Semi-transparent background
                        border: Border.all(color: Pallet.inside2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // SmallTextBox replacement
                                SizedBox(
                                  height: 35,
                                  child: TextField(
                                    controller: searchController,
                                    style: TextStyle(
                                      color: Pallet.font1,
                                      fontSize: 13,
                                    ),
                                    onChanged: (val) {
                                      setOverlayState(() {
                                        filteredItems = allFonts
                                            .where(
                                              (f) => f.toLowerCase().contains(
                                                val.toLowerCase(),
                                              ),
                                            )
                                            .toList();
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: "Search font...",
                                      hintStyle: TextStyle(
                                        color: Pallet.font3,
                                        fontSize: 13,
                                      ),
                                      fillColor: Pallet.inside2,
                                      filled: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 0,
                                            horizontal: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(5),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 250, // Limit height
                                  ),
                                  child: ValueListenableBuilder<int?>(
                                    valueListenable: hoveredIdx,
                                    builder: (context, _hoveredIdx, child) {
                                      return ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredItems.length,
                                        itemBuilder: (context, i) {
                                          final font = filteredItems[i];
                                          return MouseRegion(
                                            onEnter: (details) =>
                                                hoveredIdx.value = i,
                                            onExit: (details) =>
                                                hoveredIdx.value = null,
                                            child: InkWell(
                                              onTap: () {
                                                widget.onChanged(font);
                                                close();
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  color:
                                                      (i == _hoveredIdx ||
                                                          font == widget.value)
                                                      ? Pallet.inside3
                                                      : Colors.transparent,
                                                ),
                                                height:
                                                    30, // specific height for list items
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        font,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Pallet.font2,
                                                          fontFamily:
                                                              GoogleFonts.getFont(
                                                                font,
                                                              ).fontFamily,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    if (font == widget.value)
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
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel)
          SizedBox(
            width: 80,
            child: Text(
              "${widget.label}:",
              style: TextStyle(fontSize: 13, color: Pallet.font1),
            ),
          ),
        if (widget.showLabel) const SizedBox(width: 5),
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
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Pallet.inside2,
                borderRadius: BorderRadius.circular(5),
                border: isOpen ? Border.all(color: Pallet.inside3) : null,
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.value,
                      style: GoogleFonts.getFont(
                        widget.value,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ).copyWith(overflow: TextOverflow.ellipsis),
                      maxLines: 1,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Pallet.font2, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
