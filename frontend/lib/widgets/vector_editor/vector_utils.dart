import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'models.dart';

const _uuid = Uuid();

String generateId() => _uuid.v4();

Rect getBounds(List<PathNode> nodes) {
  if (nodes.isEmpty) return Rect.zero;
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  for (final node in nodes) {
    minX = min(minX, node.position.dx);
    minY = min(minY, node.position.dy);
    maxX = max(maxX, node.position.dx);
    maxY = max(maxY, node.position.dy);
    
    if (node.isCurve) {
       minX = min(minX, node.handleIn.dx);
       minY = min(minY, node.handleIn.dy);
       maxX = max(maxX, node.handleIn.dx);
       maxY = max(maxY, node.handleIn.dy);
       minX = min(minX, node.handleOut.dx);
       minY = min(minY, node.handleOut.dy);
       maxX = max(maxX, node.handleOut.dx);
       maxY = max(maxY, node.handleOut.dy);
    }
  }
  
  // If bounds are zero (single point), give it some size
  if (minX == maxX) maxX += 1;
  if (minY == maxY) maxY += 1;

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

String formatPathD(List<PathNode> nodes, bool closed) {
  if (nodes.isEmpty) return '';

  String d = 'M ${nodes[0].position.dx.toStringAsFixed(2)} ${nodes[0].position.dy.toStringAsFixed(2)}';

  for (int i = 1; i < nodes.length; i++) {
    final curr = nodes[i];
    final prev = nodes[i - 1];

    if (prev.isCurve || curr.isCurve) {
      d += ' C ${prev.handleOut.dx.toStringAsFixed(2)} ${prev.handleOut.dy.toStringAsFixed(2)}, '
           '${curr.handleIn.dx.toStringAsFixed(2)} ${curr.handleIn.dy.toStringAsFixed(2)}, '
           '${curr.position.dx.toStringAsFixed(2)} ${curr.position.dy.toStringAsFixed(2)}';
    } else {
      d += ' L ${curr.position.dx.toStringAsFixed(2)} ${curr.position.dy.toStringAsFixed(2)}';
    }
  }

  if (closed && nodes.length > 1) {
    final last = nodes.last;
    final first = nodes.first;
    if (last.isCurve || first.isCurve) {
       d += ' C ${last.handleOut.dx.toStringAsFixed(2)} ${last.handleOut.dy.toStringAsFixed(2)}, '
            '${first.handleIn.dx.toStringAsFixed(2)} ${first.handleIn.dy.toStringAsFixed(2)}, '
            '${first.position.dx.toStringAsFixed(2)} ${first.position.dy.toStringAsFixed(2)}';
       // We usually append Z for closed path in SVG
       d += ' Z';
    } else {
       d += ' Z';
    }
  }

  return d;
}

List<PathNode> parseSVGPath(String d) {
  // Check if it is a full SVG string and extract path
  if (d.trim().startsWith('<svg')) {
      final pathMatch = RegExp(r'd="([^"]+)"').firstMatch(d);
      if (pathMatch != null) {
          d = pathMatch.group(1)!;
          debugPrint('Extracted path from SVG tag: $d');
      } else {
          debugPrint('WARNING: Could not extract path from SVG tag');
          return [];
      }
  }

  final nodes = <PathNode>[];
  
  // Regex to tokenize commands and numbers
  final tokenRegex = RegExp(r'([a-zA-Z])|([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)');
  final matches = tokenRegex.allMatches(d);
  final tokens = matches.map((m) => m.group(0)!).toList();
  
  debugPrint('Parsing SVG Path: "$d"');
  debugPrint('Tokens found: ${tokens.length}');

  int cursor = 0;
  double currentX = 0;
  double currentY = 0;
  
  // Safety check for infinite loop
  int loopSafety = 0;
  const int maxLoops = 10000;

  double lastControlX = 0;
  double lastControlY = 0;
  String lastCommandType = '';

  bool isNum(String str) {
    return double.tryParse(str) != null;
  }

  double nextNum() {
    if (cursor >= tokens.length) return 0;
    final val = double.tryParse(tokens[cursor]);
    if (val != null) {
      cursor++;
      return val;
    }
    debugPrint('WARNING: Expected number but got "${tokens[cursor]}" at cursor $cursor');
    return 0; 
  }

  String activeCmd = '';

  while (cursor < tokens.length) {
    loopSafety++;
    if (loopSafety > maxLoops) {
        debugPrint('CRITICAL: Infinite loop detected in parseSVGPath!');
        break;
    }
    
    String token = tokens[cursor];
    
    if (!isNum(token)) {
      activeCmd = token;
      cursor++;
    } else {
      // Implicit repetition
      if (activeCmd == 'M') activeCmd = 'L';
      if (activeCmd == 'm') activeCmd = 'l';
    }

    final upperCmd = activeCmd.toUpperCase();
    final isRelative = activeCmd == activeCmd.toLowerCase();

    switch (upperCmd) {
      case 'M':
        double x = nextNum();
        double y = nextNum();
        if (isRelative) {
          x += currentX;
          y += currentY;
        }

        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(x, y),
          handleOut: Offset(x, y),
          isCurve: false,
        ));

        currentX = x;
        currentY = y;
        lastControlX = x;
        lastControlY = y;
        lastCommandType = 'M';
        break;

      case 'L':
        double x = nextNum();
        double y = nextNum();
        if (isRelative) {
          x += currentX;
          y += currentY;
        }

        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(x, y),
          handleOut: Offset(x, y),
          isCurve: false,
        ));

        currentX = x;
        currentY = y;
        lastControlX = x;
        lastControlY = y;
        lastCommandType = 'L';
        break;

      case 'H':
        double x = nextNum();
        if (isRelative) x += currentX;
        double y = currentY;

        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(x, y),
          handleOut: Offset(x, y),
          isCurve: false,
        ));

        currentX = x;
        lastControlX = x;
        lastControlY = y;
        lastCommandType = 'L';
        break;

      case 'V':
        double y = nextNum();
        if (isRelative) y += currentY;
        double x = currentX;

        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(x, y),
          handleOut: Offset(x, y),
          isCurve: false,
        ));

        currentY = y;
        lastControlX = x;
        lastControlY = y;
        lastCommandType = 'L';
        break;

      case 'C':
        double cp1x = nextNum();
        double cp1y = nextNum();
        double cp2x = nextNum();
        double cp2y = nextNum();
        double x = nextNum();
        double y = nextNum();

        if (isRelative) {
          cp1x += currentX; cp1y += currentY;
          cp2x += currentX; cp2y += currentY;
          x += currentX; y += currentY;
        }

        if (nodes.isNotEmpty) {
          final prev = nodes.last;
          nodes[nodes.length - 1] = prev.copyWith(
            handleOut: Offset(cp1x, cp1y),
            isCurve: true,
          );
        }

        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(cp2x, cp2y),
          handleOut: Offset(x, y),
          isCurve: true,
        ));

        currentX = x;
        currentY = y;
        lastControlX = cp2x;
        lastControlY = cp2y;
        lastCommandType = 'C';
        break;

      case 'S':
        double cp2x = nextNum();
        double cp2y = nextNum();
        double x = nextNum();
        double y = nextNum();

        if (isRelative) {
          cp2x += currentX; cp2y += currentY;
          x += currentX; y += currentY;
        }

        double cp1x = currentX;
        double cp1y = currentY;

        if (['C', 'S', 'Q', 'T'].contains(lastCommandType)) {
          cp1x = 2 * currentX - lastControlX;
          cp1y = 2 * currentY - lastControlY;
        }

        if (nodes.isNotEmpty) {
          final prev = nodes.last;
          nodes[nodes.length - 1] = prev.copyWith(
            handleOut: Offset(cp1x, cp1y),
            isCurve: true,
          );
        }

        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(cp2x, cp2y),
          handleOut: Offset(x, y),
          isCurve: true,
        ));

        currentX = x;
        currentY = y;
        lastControlX = cp2x;
        lastControlY = cp2y;
        lastCommandType = 'S';
        break;
        
      case 'Q':
        double qcp1x = nextNum();
        double qcp1y = nextNum();
        double x = nextNum();
        double y = nextNum();

        if (isRelative) {
            qcp1x += currentX; qcp1y += currentY;
            x += currentX; y += currentY;
        }

        // Quadratic to Cubic
        double cp1x = currentX + (2/3) * (qcp1x - currentX);
        double cp1y = currentY + (2/3) * (qcp1y - currentY);
        double cp2x = x + (2/3) * (qcp1x - x);
        double cp2y = y + (2/3) * (qcp1y - y);

        if (nodes.isNotEmpty) {
            final prev = nodes.last;
            nodes[nodes.length - 1] = prev.copyWith(
                handleOut: Offset(cp1x, cp1y),
                isCurve: true,
            );
        }

        nodes.add(PathNode(
            id: generateId(),
            position: Offset(x, y),
            handleIn: Offset(cp2x, cp2y),
            handleOut: Offset(x, y),
            isCurve: true,
        ));

        currentX = x;
        currentY = y;
        lastControlX = qcp1x;
        lastControlY = qcp1y;
        lastCommandType = 'Q';
        break;
      
      case 'T':
        double x = nextNum();
        double y = nextNum();
        
        if (isRelative) {
            x += currentX; y += currentY;
        }
        
        double qcp1x = currentX;
        double qcp1y = currentY;
        
        if (['Q', 'T'].contains(lastCommandType)) {
            qcp1x = 2 * currentX - lastControlX;
            qcp1y = 2 * currentY - lastControlY;
        }

        double cp1x = currentX + (2/3) * (qcp1x - currentX);
        double cp1y = currentY + (2/3) * (qcp1y - currentY);
        double cp2x = x + (2/3) * (qcp1x - x);
        double cp2y = y + (2/3) * (qcp1y - y);
        
        if (nodes.isNotEmpty) {
            final prev = nodes.last;
            nodes[nodes.length - 1] = prev.copyWith(
                handleOut: Offset(cp1x, cp1y),
                isCurve: true,
            );
        }

        nodes.add(PathNode(
            id: generateId(),
            position: Offset(x, y),
            handleIn: Offset(cp2x, cp2y),
            handleOut: Offset(x, y),
            isCurve: true,
        ));
        
        currentX = x;
        currentY = y;
        lastControlX = qcp1x;
        lastControlY = qcp1y;
        lastCommandType = 'T';
        break;

      case 'A':
        // Skip args
        nextNum(); nextNum(); nextNum(); nextNum(); nextNum();
        double x = nextNum();
        double y = nextNum();
        if (isRelative) { x += currentX; y += currentY; }
        
        nodes.add(PathNode(
          id: generateId(),
          position: Offset(x, y),
          handleIn: Offset(x, y),
          handleOut: Offset(x, y),
          isCurve: false,
        ));
        
        currentX = x; currentY = y;
        lastControlX = x; lastControlY = y;
        lastCommandType = 'L';
        break;

      case 'Z':
        // Done
        break;
        
      default:
        // Skip unknown
        break;
    }
  }

  return nodes;
}
