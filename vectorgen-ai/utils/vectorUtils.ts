import { PathNode, VectorPath, Point } from '../types';

export const generateId = (): string => Math.random().toString(36).substr(2, 9);

export const formatPathD = (nodes: PathNode[], closed: boolean): string => {
  if (nodes.length === 0) return '';

  let d = `M ${nodes[0].x.toFixed(2)} ${nodes[0].y.toFixed(2)}`;

  for (let i = 1; i < nodes.length; i++) {
    const curr = nodes[i];
    const prev = nodes[i - 1];

    if (prev.isCurve || curr.isCurve) {
        // Cubic Bezier
        d += ` C ${prev.handleOut.x.toFixed(2)} ${prev.handleOut.y.toFixed(2)}, ${curr.handleIn.x.toFixed(2)} ${curr.handleIn.y.toFixed(2)}, ${curr.x.toFixed(2)} ${curr.y.toFixed(2)}`;
    } else {
        // Line
        d += ` L ${curr.x.toFixed(2)} ${curr.y.toFixed(2)}`;
    }
  }

  if (closed && nodes.length > 1) {
    const last = nodes[nodes.length - 1];
    const first = nodes[0];
     if (last.isCurve || first.isCurve) {
        d += ` C ${last.handleOut.x.toFixed(2)} ${last.handleOut.y.toFixed(2)}, ${first.handleIn.x.toFixed(2)} ${first.handleIn.y.toFixed(2)}, ${first.x.toFixed(2)} ${first.y.toFixed(2)}`;
    } else {
        d += ` Z`;
    }
  }

  return d;
};

// Basic distance check
export const distance = (p1: Point, p2: Point) => Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));

// --- Math Helpers for Node Insertion ---

export const lerp = (p1: Point, p2: Point, t: number): Point => ({
  x: p1.x + (p2.x - p1.x) * t,
  y: p1.y + (p2.y - p1.y) * t,
});

export const getCubicPoint = (p0: Point, p1: Point, p2: Point, p3: Point, t: number): Point => {
  const a = lerp(p0, p1, t);
  const b = lerp(p1, p2, t);
  const c = lerp(p2, p3, t);
  const d = lerp(a, b, t);
  const e = lerp(b, c, t);
  return lerp(d, e, t);
};

const getClosestTOnLine = (p0: Point, p1: Point, p: Point): number => {
    const dx = p1.x - p0.x;
    const dy = p1.y - p0.y;
    if (dx === 0 && dy === 0) return 0;
    const t = ((p.x - p0.x) * dx + (p.y - p0.y) * dy) / (dx * dx + dy * dy);
    return Math.max(0, Math.min(1, t));
};

const getClosestTOnCubic = (p0: Point, p1: Point, p2: Point, p3: Point, p: Point): {t: number, dist: number} => {
    let bestT = 0;
    let minDst = Infinity;
    const steps = 40; 
    for (let i = 0; i <= steps; i++) {
        const t = i / steps;
        const pos = getCubicPoint(p0, p1, p2, p3, t);
        const d = distance(pos, p);
        if (d < minDst) {
            minDst = d;
            bestT = t;
        }
    }
    // Binary search refinement
    let start = Math.max(0, bestT - 0.05);
    let end = Math.min(1, bestT + 0.05);
    for (let i = 0; i < 5; i++) {
        const mid1 = start + (end - start) / 3;
        const mid2 = end - (end - start) / 3;
        const dist1 = distance(getCubicPoint(p0, p1, p2, p3, mid1), p);
        const dist2 = distance(getCubicPoint(p0, p1, p2, p3, mid2), p);
        if (dist1 < dist2) {
            end = mid2;
            minDst = dist1;
            bestT = mid1;
        } else {
            start = mid1;
            minDst = dist2;
            bestT = mid2;
        }
    }
    
    return { t: bestT, dist: minDst };
};

// Returns the coordinates on the path closest to the cursor, or null if too far
export const getClosestPointOnPath = (nodes: PathNode[], closed: boolean, clickPoint: Point, threshold: number = 10): Point | null => {
   let bestDist = Infinity;
   let bestPoint: Point | null = null;
   
   const count = closed ? nodes.length : nodes.length - 1;
   
   for (let i = 0; i < count; i++) {
       const p0 = nodes[i];
       const p1 = nodes[(i + 1) % nodes.length];
       
       let dist = Infinity;
       let point: Point = {x: 0, y: 0};

       if (p1.isCurve) {
            const res = getClosestTOnCubic(
                {x:p0.x, y:p0.y}, 
                p0.handleOut, 
                p1.handleIn, 
                {x:p1.x, y:p1.y}, 
                clickPoint
            );
            dist = res.dist;
            point = getCubicPoint({x:p0.x, y:p0.y}, p0.handleOut, p1.handleIn, {x:p1.x, y:p1.y}, res.t);
       } else {
            const t = getClosestTOnLine({x:p0.x, y:p0.y}, {x:p1.x, y:p1.y}, clickPoint);
            point = lerp({x:p0.x, y:p0.y}, {x:p1.x, y:p1.y}, t);
            dist = distance(point, clickPoint);
       }
       
       if (dist < bestDist) {
           bestDist = dist;
           bestPoint = point;
       }
   }
   
   return bestDist <= threshold ? bestPoint : null;
};

export const insertNodeAt = (nodes: PathNode[], closed: boolean, clickPoint: Point, threshold: number = 20): PathNode[] | null => {
   let bestDist = Infinity;
   let insertion: { index: number, t: number, p0:PathNode, p1:PathNode } | null = null;
   
   const count = closed ? nodes.length : nodes.length - 1;
   
   for (let i = 0; i < count; i++) {
       const p0 = nodes[i];
       const p1 = nodes[(i + 1) % nodes.length];
       
       let t = 0;
       let dist = Infinity;

       if (p1.isCurve) {
            const res = getClosestTOnCubic(
                {x:p0.x, y:p0.y}, 
                p0.handleOut, 
                p1.handleIn, 
                {x:p1.x, y:p1.y}, 
                clickPoint
            );
            t = res.t;
            dist = res.dist;
       } else {
            t = getClosestTOnLine({x:p0.x, y:p0.y}, {x:p1.x, y:p1.y}, clickPoint);
            const pos = lerp({x:p0.x, y:p0.y}, {x:p1.x, y:p1.y}, t);
            dist = distance(pos, clickPoint);
       }
       
       if (dist < bestDist) {
           bestDist = dist;
           insertion = { index: i, t, p0, p1 };
       }
   }
   
   if (bestDist > threshold || !insertion) return null;
   
   const { index, t, p0, p1 } = insertion;
   const newNodes = [...nodes];
   const nextIndex = (index + 1) % nodes.length;
   const newNodeId = generateId();

   if (p1.isCurve) {
       const P0 = {x:p0.x, y:p0.y};
       const P1 = p0.handleOut;
       const P2 = p1.handleIn;
       const P3 = {x:p1.x, y:p1.y};
       
       const q0 = lerp(P0, P1, t);
       const q1 = lerp(P1, P2, t);
       const q2 = lerp(P2, P3, t);
       const r0 = lerp(q0, q1, t);
       const r1 = lerp(q1, q2, t);
       const s = lerp(r0, r1, t); 
       
       const newNode: PathNode = {
           id: newNodeId,
           x: s.x,
           y: s.y,
           handleIn: r0, 
           handleOut: r1, 
           isCurve: true
       };
       
       newNodes[index] = { ...p0, handleOut: q0 };
       newNodes[nextIndex] = { ...p1, handleIn: q2 };
       
       if (nextIndex === 0 && closed) {
           newNodes.push(newNode);
       } else {
           newNodes.splice(index + 1, 0, newNode);
       }
   } else {
       const pos = lerp({x:p0.x, y:p0.y}, {x:p1.x, y:p1.y}, t);
       const newNode: PathNode = {
           id: newNodeId,
           x: pos.x,
           y: pos.y,
           handleIn: {x: pos.x, y: pos.y},
           handleOut: {x: pos.x, y: pos.y},
           isCurve: false
       };
       
       if (nextIndex === 0 && closed) {
           newNodes.push(newNode);
       } else {
           newNodes.splice(index + 1, 0, newNode);
       }
   }
   
   return newNodes;
};

// --- End Math Helpers ---

// Parse a robust SVG Path string
export const parseSVGPath = (d: string): PathNode[] => {
    const nodes: PathNode[] = [];
    
    // Regex to tokenize commands and numbers. 
    // Matches:
    // 1. Single letters for commands (a-z, A-Z)
    // 2. Numbers (integers, decimals, scientific notation, starting with + or -)
    const tokenRegex = /([a-zA-Z])|([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)/g;
    
    const tokens: string[] = [];
    let match;
    while ((match = tokenRegex.exec(d)) !== null) {
        tokens.push(match[0]);
    }

    let cursor = 0;
    let currentX = 0;
    let currentY = 0;
    
    // For S and T commands, we need to track the last used control point
    // to calculate reflection. If last cmd wasn't curve, these default to current point.
    let lastControlX = 0;
    let lastControlY = 0;
    let lastCommandType = ''; // 'C', 'S', 'Q', 'T', 'L', 'M' etc

    // Helper to check if string is a number
    const isNum = (str: string) => /[-+.\d]/.test(str);
    
    // Helper to get next number from tokens
    const nextNum = () => {
        if (cursor >= tokens.length) return 0;
        const val = parseFloat(tokens[cursor]);
        if (!isNaN(val)) cursor++;
        return val;
    }

    // Keep track of active command for implicit repetition
    let activeCmd = '';

    while (cursor < tokens.length) {
        let token = tokens[cursor];
        
        if (!isNum(token)) {
            activeCmd = token;
            cursor++;
        } else {
            // Implicit repetition handling
            if (activeCmd === 'M') activeCmd = 'L';
            if (activeCmd === 'm') activeCmd = 'l';
            // Otherwise keep activeCmd as is
        }

        const upperCmd = activeCmd.toUpperCase();
        const isRelative = activeCmd === activeCmd.toLowerCase();

        switch (upperCmd) {
            case 'M': {
                let x = nextNum();
                let y = nextNum();
                if (isRelative) {
                    x += currentX;
                    y += currentY;
                }
                
                nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: {x, y},
                    handleOut: {x, y},
                    isCurve: false
                });
                
                currentX = x;
                currentY = y;
                lastControlX = x;
                lastControlY = y;
                lastCommandType = 'M';
                break;
            }
            case 'L': {
                let x = nextNum();
                let y = nextNum();
                if (isRelative) {
                    x += currentX;
                    y += currentY;
                }

                nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: {x, y},
                    handleOut: {x, y},
                    isCurve: false
                });

                currentX = x;
                currentY = y;
                lastControlX = x;
                lastControlY = y;
                lastCommandType = 'L';
                break;
            }
            case 'H': {
                let x = nextNum();
                if (isRelative) x += currentX;
                const y = currentY;
                
                nodes.push({
                     id: generateId(),
                     x, y,
                     handleIn: {x, y},
                     handleOut: {x, y},
                     isCurve: false
                });
                
                currentX = x;
                lastControlX = x;
                lastControlY = y;
                lastCommandType = 'L'; // Treat as Line
                break;
            }
            case 'V': {
                let y = nextNum();
                if (isRelative) y += currentY;
                const x = currentX;
                
                nodes.push({
                     id: generateId(),
                     x, y,
                     handleIn: {x, y},
                     handleOut: {x, y},
                     isCurve: false
                });
                
                currentY = y;
                lastControlX = x;
                lastControlY = y;
                lastCommandType = 'L'; // Treat as Line
                break;
            }
            case 'C': {
                let cp1x = nextNum();
                let cp1y = nextNum();
                let cp2x = nextNum();
                let cp2y = nextNum();
                let x = nextNum();
                let y = nextNum();

                if (isRelative) {
                    cp1x += currentX; cp1y += currentY;
                    cp2x += currentX; cp2y += currentY;
                    x += currentX; y += currentY;
                }

                // Update previous node's handleOut
                if (nodes.length > 0) {
                    const prev = nodes[nodes.length - 1];
                    prev.handleOut = { x: cp1x, y: cp1y };
                    prev.isCurve = true;
                }

                nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: { x: cp2x, y: cp2y },
                    handleOut: { x, y }, 
                    isCurve: true
                });

                currentX = x;
                currentY = y;
                lastControlX = cp2x;
                lastControlY = cp2y;
                lastCommandType = 'C';
                break;
            }
            case 'S': {
                let cp2x = nextNum();
                let cp2y = nextNum();
                let x = nextNum();
                let y = nextNum();

                if (isRelative) {
                    cp2x += currentX; cp2y += currentY;
                    x += currentX; y += currentY;
                }

                // Calculate cp1 (reflection of lastControlPoint)
                // If previous command wasn't C or S, cp1 = currentPoint
                let cp1x = currentX;
                let cp1y = currentY;
                
                if (['C', 'S', 'Q', 'T'].includes(lastCommandType)) {
                     cp1x = 2 * currentX - lastControlX;
                     cp1y = 2 * currentY - lastControlY;
                }

                // Update previous node
                if (nodes.length > 0) {
                    const prev = nodes[nodes.length - 1];
                    prev.handleOut = { x: cp1x, y: cp1y };
                    prev.isCurve = true;
                }

                nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: { x: cp2x, y: cp2y },
                    handleOut: { x, y },
                    isCurve: true
                });

                currentX = x;
                currentY = y;
                lastControlX = cp2x;
                lastControlY = cp2y;
                lastCommandType = 'S';
                break;
            }
             case 'Q': {
                // Quadratic Bezier (x1 y1 x y) -> Convert to Cubic
                let qcp1x = nextNum();
                let qcp1y = nextNum();
                let x = nextNum();
                let y = nextNum();

                if (isRelative) {
                    qcp1x += currentX; qcp1y += currentY;
                    x += currentX; y += currentY;
                }

                // Convert Quadratic to Cubic control points
                // CP1 = P0 + 2/3 (QP1 - P0)
                // CP2 = P + 2/3 (QP1 - P)
                const cp1x = currentX + (2/3) * (qcp1x - currentX);
                const cp1y = currentY + (2/3) * (qcp1y - currentY);
                const cp2x = x + (2/3) * (qcp1x - x);
                const cp2y = y + (2/3) * (qcp1y - y);

                if (nodes.length > 0) {
                    const prev = nodes[nodes.length - 1];
                    prev.handleOut = { x: cp1x, y: cp1y };
                    prev.isCurve = true;
                }

                nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: { x: cp2x, y: cp2y },
                    handleOut: { x, y },
                    isCurve: true
                });

                currentX = x;
                currentY = y;
                lastControlX = qcp1x; // Keep original quad control for T reflection
                lastControlY = qcp1y;
                lastCommandType = 'Q';
                break;
            }
            case 'T': {
                // Smooth Quadratic -> Convert to Cubic
                let x = nextNum();
                let y = nextNum();
                
                if (isRelative) {
                    x += currentX; y += currentY;
                }
                
                // Reflect control point
                let qcp1x = currentX;
                let qcp1y = currentY;
                
                 if (['Q', 'T'].includes(lastCommandType)) {
                     qcp1x = 2 * currentX - lastControlX;
                     qcp1y = 2 * currentY - lastControlY;
                 }

                const cp1x = currentX + (2/3) * (qcp1x - currentX);
                const cp1y = currentY + (2/3) * (qcp1y - currentY);
                const cp2x = x + (2/3) * (qcp1x - x);
                const cp2y = y + (2/3) * (qcp1y - y);
                
                if (nodes.length > 0) {
                    const prev = nodes[nodes.length - 1];
                    prev.handleOut = { x: cp1x, y: cp1y };
                    prev.isCurve = true;
                }

                nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: { x: cp2x, y: cp2y },
                    handleOut: { x, y },
                    isCurve: true
                });
                
                currentX = x;
                currentY = y;
                lastControlX = qcp1x;
                lastControlY = qcp1y;
                lastCommandType = 'T';
                break;
            }
            case 'A': {
                // Arc command - simplified to Line for this editor (Arc to Bezier is complex)
                // A rx ry x-axis-rotation large-arc-flag sweep-flag x y
                nextNum(); nextNum(); nextNum(); nextNum(); nextNum(); // Consume args
                let x = nextNum();
                let y = nextNum();
                if (isRelative) { x += currentX; y += currentY; }
                
                 nodes.push({
                    id: generateId(),
                    x, y,
                    handleIn: {x, y},
                    handleOut: {x, y},
                    isCurve: false
                });
                currentX = x; currentY = y;
                lastControlX = x; lastControlY = y;
                lastCommandType = 'L';
                break;
            }
            case 'Z': {
                // Z usually means close path. 
                // We don't add a node, but we stop the loop if it's the end of data.
                // Or we can flag the last path as closed.
                // But this function returns a list of nodes.
                // We'll rely on the parser caller to set closed=true if Z is detected, 
                // OR we can't really do it here easily without changing return type.
                // But for import logic, we check string ending with Z separately.
                break;
            }
        }
    }
    return nodes;
}

// Deprecated: Alias for backward compatibility if needed, but we replace usage.
export const parseSimpleSvgPath = parseSVGPath;

export const parseSVGString = (svgString: string): VectorPath[] => {
  const parser = new DOMParser();
  // Wrap in svg tag if it's just a path string or partial html
  const stringToParse = svgString.includes('<svg') ? svgString : `<svg>${svgString}</svg>`;
  const doc = parser.parseFromString(stringToParse, "image/svg+xml");
  const paths: VectorPath[] = [];
  const pathElements = doc.querySelectorAll('path');

  pathElements.forEach((el, index) => {
    const d = el.getAttribute('d');
    if (d) {
      const nodes = parseSVGPath(d);
      if (nodes.length > 0) {
        
        let fill = el.getAttribute('fill');
        // Handle currentColor or missing fill by defaulting to theme text color
        if (!fill || fill === 'currentColor') {
            fill = '#e0e0e0';
        }
        
        let stroke = el.getAttribute('stroke');
        if (stroke === 'currentColor') {
            stroke = '#e0e0e0';
        }
        if (!stroke) {
            stroke = 'none';
        }

        paths.push({
          id: `import-${Date.now()}-${index}`,
          name: el.getAttribute('id') || `Imported Path ${index + 1}`,
          nodes: nodes,
          closed: d.toLowerCase().includes('z'),
          fill: fill,
          stroke: stroke, 
          strokeWidth: parseFloat(el.getAttribute('stroke-width') || '0'),
          isVisible: true,
          isLocked: false
        });
      }
    }
  });
  return paths;
};