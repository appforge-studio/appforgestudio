import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'property_icon_selector.dart';

class PropertyIconField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;

  const PropertyIconField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Get.dialog(PropertyIconSelector(onIconSelected: onChanged));
          },
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (value.isNotEmpty)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: SvgPicture.string(value),
                  )
                else
                  const Icon(Icons.image_not_supported),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.isNotEmpty ? 'SVG Selected' : 'Select Icon',
                    style: TextStyle(
                      color: value.isNotEmpty ? Colors.black : Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
