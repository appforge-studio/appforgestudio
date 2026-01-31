enum Axis { horizontal, vertical }

class AlignmentGuide {
  final double
  position; // The pixel position on the canvas (x for vertical, y for horizontal)
  final Axis axis;
  final bool isCenter;

  const AlignmentGuide({
    required this.position,
    required this.axis,
    this.isCenter = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlignmentGuide &&
        other.position == position &&
        other.axis == axis &&
        other.isCenter == isCenter;
  }

  @override
  int get hashCode => Object.hash(position, axis, isCenter);
}
