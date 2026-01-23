import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'property_icon_selector.dart';

import '../utilities/pallet.dart';

class PropertyIconField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const PropertyIconField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showLabel = true,
  });

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLabel)
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: TextStyle(fontSize: 13, color: Pallet.font1),
            ),
          ),
        if (showLabel) const SizedBox(width: 5),
        Expanded(
          child: InkWell(
            onTap: () {
              Get.dialog(PropertyIconSelector(onIconSelected: onChanged));
            },
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Pallet.inside2,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                children: [
                  if (value.isNotEmpty)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: SvgPicture.string(
                        value,
                        colorFilter: ColorFilter.mode(
                          Pallet.font1,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.image_not_supported,
                      size: 20,
                      color: Pallet.font3,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value.isNotEmpty ? 'SVG Selected' : 'Select',
                      style: TextStyle(color: Pallet.font1, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 18, color: Pallet.font3),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
