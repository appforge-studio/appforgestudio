import 'dart:ui';

class PathNode {
  String id;
  Offset position;
  Offset handleIn;
  Offset handleOut;
  bool isCurve;
  bool isMove;

  PathNode({
    required this.id,
    required this.position,
    required this.handleIn,
    required this.handleOut,
    required this.isCurve,
    this.isMove = false,
  });

  PathNode copyWith({
    String? id,
    Offset? position,
    Offset? handleIn,
    Offset? handleOut,
    bool? isCurve,
    bool? isMove,
  }) {
    return PathNode(
      id: id ?? this.id,
      position: position ?? this.position,
      handleIn: handleIn ?? this.handleIn,
      handleOut: handleOut ?? this.handleOut,
      isCurve: isCurve ?? this.isCurve,
      isMove: isMove ?? this.isMove,
    );
  }
}

class VectorPath {
  String id;
  String name;
  List<PathNode> nodes;
  bool closed;
  Color? fill;
  Color? stroke;
  double strokeWidth;

  VectorPath({
    required this.id,
    this.name = 'Path',
    required this.nodes,
    this.closed = false,
    this.fill,
    this.stroke,
    this.strokeWidth = 1.0,
  });
}
