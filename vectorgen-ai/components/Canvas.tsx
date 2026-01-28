import React, { useRef, useState, useEffect } from 'react';
import { VectorPath, PathNode, ToolType, Point, DragState } from '../types';
import { formatPathD, distance, generateId, insertNodeAt, getClosestPointOnPath } from '../utils/vectorUtils';

interface CanvasProps {
  paths: VectorPath[];
  selectedPathId: string | null;
  activeTool: ToolType;
  onPathUpdate: (pathId: string, nodes: PathNode[]) => void;
  onSelectPath: (pathId: string | null) => void;
  onAddPath: (path: VectorPath) => void;
}

const Canvas: React.FC<CanvasProps> = ({
  paths,
  selectedPathId,
  activeTool,
  onPathUpdate,
  onSelectPath,
  onAddPath,
}) => {
  const svgRef = useRef<SVGSVGElement>(null);
  const [dragState, setDragState] = useState<DragState>({
    isDragging: false,
    mode: null,
    targetId: null,
    startPoint: { x: 0, y: 0 },
    originalNodes: [],
  });
  
  // For Pen tool preview
  const [penPreview, setPenPreview] = useState<Point | null>(null);
  // For Node tool point insertion preview
  const [hoverInsertPoint, setHoverInsertPoint] = useState<Point | null>(null);

  // Handle Escape key
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        // Cancel any active drag
        if (dragState.isDragging) {
           setDragState(prev => ({ ...prev, isDragging: false, mode: null, targetId: null }));
        }
        // Deselect path to stop drawing (removes rubber band)
        onSelectPath(null);
      }
      
      // Delete key to delete selected path
      if ((e.key === 'Delete' || e.key === 'Backspace') && selectedPathId && !dragState.isDragging) {
          // This would require a delete callback, ignoring for now as per instructions to only update existing logic
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [dragState.isDragging, onSelectPath, selectedPathId]);

  const getSvgCoords = (e: React.MouseEvent | MouseEvent): Point => {
    if (!svgRef.current) return { x: 0, y: 0 };
    const CTM = svgRef.current.getScreenCTM();
    if (!CTM) return { x: 0, y: 0 };
    return {
      x: (e.clientX - CTM.e) / CTM.a,
      y: (e.clientY - CTM.f) / CTM.d,
    };
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    const coords = getSvgCoords(e);

    // 1. PEN TOOL LOGIC
    if (activeTool === ToolType.PEN) {
      if (!selectedPathId) {
        // Start new path
        const newId = generateId();
        const firstNode: PathNode = {
            id: generateId(),
            x: coords.x,
            y: coords.y,
            handleIn: { x: coords.x, y: coords.y },
            handleOut: { x: coords.x, y: coords.y },
            isCurve: false
        };
        const newPath: VectorPath = {
            id: newId,
            name: `Path ${paths.length + 1}`,
            nodes: [firstNode],
            closed: false,
            fill: 'none',
            stroke: '#e0e0e0',
            strokeWidth: 2,
            isVisible: true,
            isLocked: false
        };
        onAddPath(newPath);
        onSelectPath(newId);
      } else {
        // Add point to existing path
        const path = paths.find(p => p.id === selectedPathId);
        if (path) {
            const newNode: PathNode = {
                id: generateId(),
                x: coords.x,
                y: coords.y,
                handleIn: { x: coords.x, y: coords.y },
                handleOut: { x: coords.x, y: coords.y },
                isCurve: false
            };
            onPathUpdate(selectedPathId, [...path.nodes, newNode]);
            
            // Initiate drag for handle creation immediately upon click
            setDragState({
                isDragging: true,
                mode: 'HANDLE_OUT', // Dragging mouse creates the curve by pulling handleOut
                targetId: newNode.id, 
                subTargetId: null,
                startPoint: coords,
                originalNodes: [...path.nodes, newNode]
            });
        }
      }
      return;
    }

    // 2. SELECTION / NODE TOOL logic handled via onMouseDown on specific elements below
    // If clicking empty space:
    if (e.target === svgRef.current) {
        onSelectPath(null);
    }
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    const coords = getSvgCoords(e);
    
    // Pen Preview
    if (activeTool === ToolType.PEN) {
        setPenPreview(coords);
    }

    // Node Tool Preview (Add Point)
    if (activeTool === ToolType.NODE && selectedPathId && !dragState.isDragging) {
        const path = paths.find(p => p.id === selectedPathId);
        if (path) {
            // Check if hovering ANY existing node first
            const hoveringNode = path.nodes.some(n => distance(n, coords) < 8) || 
                                 path.nodes.some(n => n.isCurve && (distance(n.handleIn, coords) < 6 || distance(n.handleOut, coords) < 6));
            
            if (!hoveringNode) {
                // Not hovering a node, check if near the path stroke
                const pointOnPath = getClosestPointOnPath(path.nodes, path.closed, coords, 10);
                setHoverInsertPoint(pointOnPath);
            } else {
                setHoverInsertPoint(null);
            }
        }
    } else {
        setHoverInsertPoint(null);
    }

    if (!dragState.isDragging || !selectedPathId) return;

    const path = paths.find(p => p.id === selectedPathId);
    if (!path) return;

    const dx = coords.x - dragState.startPoint.x;
    const dy = coords.y - dragState.startPoint.y;

    const updatedNodes = path.nodes.map(node => {
        // DRAG WHOLE PATH
        if (dragState.mode === 'WHOLE_PATH') {
             const original = dragState.originalNodes.find(n => n.id === node.id);
             if (!original) return node;
             return {
                 ...node,
                 x: original.x + dx,
                 y: original.y + dy,
                 handleIn: { x: original.handleIn.x + dx, y: original.handleIn.y + dy },
                 handleOut: { x: original.handleOut.x + dx, y: original.handleOut.y + dy },
             };
        }

        // DRAG ANCHOR
        if (dragState.mode === 'ANCHOR' && node.id === dragState.targetId) {
            const original = dragState.originalNodes.find(n => n.id === node.id)!;
            return {
                ...node,
                x: original.x + dx,
                y: original.y + dy,
                handleIn: { x: original.handleIn.x + dx, y: original.handleIn.y + dy },
                handleOut: { x: original.handleOut.x + dx, y: original.handleOut.y + dy },
            };
        }
        
        // DRAG HANDLE IN
        if (dragState.mode === 'HANDLE_IN' && node.id === dragState.targetId) {
             const original = dragState.originalNodes.find(n => n.id === node.id)!;
             // If smoothing is desired, handleOut should mirror, but keeping it simple for now (independent handles)
             return {
                 ...node,
                 handleIn: { x: original.handleIn.x + dx, y: original.handleIn.y + dy },
                 isCurve: true
             };
        }

        // DRAG HANDLE OUT
        if (dragState.mode === 'HANDLE_OUT' && node.id === dragState.targetId) {
             const original = dragState.originalNodes.find(n => n.id === node.id)!;
             // Pen tool logic: when creating a point, dragging moves handleOut AND mirrors handleIn
             if (activeTool === ToolType.PEN) {
                  return {
                     ...node,
                     handleOut: { x: original.handleOut.x + dx, y: original.handleOut.y + dy },
                     handleIn: { x: original.handleIn.x - dx, y: original.handleIn.y - dy },
                     isCurve: true
                  }
             }
             
             return {
                 ...node,
                 handleOut: { x: original.handleOut.x + dx, y: original.handleOut.y + dy },
                 isCurve: true
             };
        }

        return node;
    });

    onPathUpdate(selectedPathId, updatedNodes);
  };

  const handleMouseUp = () => {
    setDragState(prev => ({ ...prev, isDragging: false, mode: null, targetId: null }));
  };

  const handleNodeDoubleClick = (e: React.MouseEvent, node: PathNode, path: VectorPath) => {
    e.stopPropagation();
    
    // Toggle Curve <-> Sharp
    const shouldBeCurve = !node.isCurve;
    let newHandleIn = { ...node.handleIn };
    let newHandleOut = { ...node.handleOut };
    
    if (shouldBeCurve) {
        // Make Smooth
        // Logic: Calculate a tangent based on previous and next points
        const nodeIndex = path.nodes.findIndex(n => n.id === node.id);
        const prev = path.nodes[nodeIndex - 1];
        const next = path.nodes[nodeIndex + 1];
        
        // Determine angle
        let angle = 0;
        if (prev && next) {
            angle = Math.atan2(next.y - prev.y, next.x - prev.x);
        } else if (prev) {
            angle = Math.atan2(node.y - prev.y, node.x - prev.x);
        } else if (next) {
            angle = Math.atan2(next.y - node.y, next.x - node.x);
        }

        const dist = 30; // Default handle length
        newHandleIn = {
            x: node.x - Math.cos(angle) * dist,
            y: node.y - Math.sin(angle) * dist
        };
        newHandleOut = {
            x: node.x + Math.cos(angle) * dist,
            y: node.y + Math.sin(angle) * dist
        };
    } else {
        // Make Sharp: Collapse handles to anchor
        newHandleIn = { x: node.x, y: node.y };
        newHandleOut = { x: node.x, y: node.y };
    }

    const updatedNodes = path.nodes.map(n => 
        n.id === node.id ? { 
            ...n, 
            isCurve: shouldBeCurve,
            handleIn: newHandleIn,
            handleOut: newHandleOut
        } : n
    );
    
    onPathUpdate(path.id, updatedNodes);
  };

  // --- Render Helpers ---

  const renderPath = (path: VectorPath) => {
    const canSelect = activeTool === ToolType.SELECT || activeTool === ToolType.NODE;
    const isHoverInsertion = activeTool === ToolType.NODE && selectedPathId === path.id && hoverInsertPoint;
    
    return (
      <g key={path.id}>
        {/* Hit Area - Wider transparent stroke for easier selection */}
        <path
            d={formatPathD(path.nodes, path.closed)}
            fill="none"
            stroke="rgba(0,0,0,0)" // Explicit transparent color for better browser support
            strokeWidth={Math.max(12, path.strokeWidth + 10)}
            strokeLinecap="round"
            strokeLinejoin="round"
            className={isHoverInsertion ? 'cursor-crosshair' : (canSelect ? 'cursor-move' : '')} // Cursor move for hit area
            pointerEvents="stroke" // Ensure we catch clicks on the stroke
            onMouseDown={(e) => {
                // ADDED: Logic for inserting point when clicking the path stroke directly
                if (isHoverInsertion) {
                    e.stopPropagation();
                    const coords = getSvgCoords(e);
                    const newNodes = insertNodeAt(path.nodes, path.closed, coords);
                    if (newNodes) {
                        onPathUpdate(path.id, newNodes);
                        setHoverInsertPoint(null);
                    }
                    return;
                }

                if (canSelect) {
                    e.stopPropagation();
                    onSelectPath(path.id);
                    
                    if (activeTool === ToolType.SELECT) {
                        setDragState({
                            isDragging: true,
                            mode: 'WHOLE_PATH',
                            targetId: path.id,
                            startPoint: getSvgCoords(e),
                            originalNodes: path.nodes
                        });
                    }
                }
            }}
        />
        
        {/* Visible Path */}
        <path
            d={formatPathD(path.nodes, path.closed)}
            fill={path.fill}
            stroke={path.stroke}
            strokeWidth={path.strokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
            pointerEvents="none" // Pass events to hit area/fill below (actually hit area is above, so this is just visual)
            className={`${selectedPathId === path.id ? 'opacity-80' : 'opacity-100'}`}
        />
      </g>
    );
  };

  const renderControls = () => {
    if (!selectedPathId) return null;
    const path = paths.find(p => p.id === selectedPathId);
    if (!path) return null;

    return (
      <g>
        {/* Preview Insertion Point */}
        {activeTool === ToolType.NODE && hoverInsertPoint && (
            <circle 
                cx={hoverInsertPoint.x} 
                cy={hoverInsertPoint.y} 
                r={4} 
                fill="#0078d4" 
                opacity={0.5} 
                className="pointer-events-none" 
            />
        )}

        {/* Connection Lines (Handles) */}
        {path.nodes.map((node) => (
             node.isCurve && (activeTool === ToolType.NODE || activeTool === ToolType.PEN) ? (
                 <React.Fragment key={`lines-${node.id}`}>
                    <line x1={node.x} y1={node.y} x2={node.handleIn.x} y2={node.handleIn.y} stroke="#0078d4" strokeWidth="1" opacity="0.6" className="pointer-events-none" />
                    <line x1={node.x} y1={node.y} x2={node.handleOut.x} y2={node.handleOut.y} stroke="#0078d4" strokeWidth="1" opacity="0.6" className="pointer-events-none" />
                 </React.Fragment>
             ) : null
        ))}

        {/* Anchor Points */}
        {path.nodes.map((node) => (
          <React.Fragment key={node.id}>
             {/* Main Anchor */}
            <circle
              cx={node.x}
              cy={node.y}
              r={activeTool === ToolType.NODE ? 5 : 4}
              fill={activeTool === ToolType.NODE ? "#fff" : "#0078d4"}
              stroke="#0078d4"
              strokeWidth="2"
              className="cursor-pointer"
              onDoubleClick={(e) => handleNodeDoubleClick(e, node, path)}
              onMouseDown={(e) => {
                if (activeTool === ToolType.NODE) {
                    e.stopPropagation();
                    setDragState({
                        isDragging: true,
                        mode: 'ANCHOR',
                        targetId: node.id,
                        startPoint: getSvgCoords(e),
                        originalNodes: path.nodes
                    });
                } else if (activeTool === ToolType.PEN && node === path.nodes[0] && path.nodes.length > 1) {
                    // Close path logic
                     e.stopPropagation();
                     onPathUpdate(path.id, [...path.nodes]); 
                     // In a real app we'd set closed=true here, assuming parent handles it or we update prop
                }
              }}
            />
            
            {/* Control Handles - Only visible in Node Tool or while drawing */}
            {node.isCurve && (activeTool === ToolType.NODE) && (
                <>
                    {/* Handle In */}
                    <circle
                        cx={node.handleIn.x}
                        cy={node.handleIn.y}
                        r={4}
                        fill="#0078d4"
                        className="cursor-pointer"
                        onMouseDown={(e) => {
                            e.stopPropagation();
                             setDragState({
                                isDragging: true,
                                mode: 'HANDLE_IN',
                                targetId: node.id,
                                startPoint: getSvgCoords(e),
                                originalNodes: path.nodes
                            });
                        }}
                    />
                     {/* Handle Out */}
                     <circle
                        cx={node.handleOut.x}
                        cy={node.handleOut.y}
                        r={4}
                        fill="#0078d4"
                        className="cursor-pointer"
                        onMouseDown={(e) => {
                            e.stopPropagation();
                             setDragState({
                                isDragging: true,
                                mode: 'HANDLE_OUT',
                                targetId: node.id,
                                startPoint: getSvgCoords(e),
                                originalNodes: path.nodes
                            });
                        }}
                    />
                </>
            )}
          </React.Fragment>
        ))}
      </g>
    );
  };
  
  // Pen rubber band
  const renderRubberBand = () => {
    if (activeTool === ToolType.PEN && selectedPathId && penPreview) {
        const path = paths.find(p => p.id === selectedPathId);
        if (path && path.nodes.length > 0) {
            const lastNode = path.nodes[path.nodes.length - 1];
            return (
                <line 
                    x1={lastNode.x} 
                    y1={lastNode.y} 
                    x2={penPreview.x} 
                    y2={penPreview.y} 
                    stroke="#0078d4" 
                    strokeWidth="1" 
                    strokeDasharray="4 2"
                    className="pointer-events-none"
                />
            )
        }
    }
    return null;
  }

  return (
    <div className="flex-1 bg-[#1e1e1e] relative overflow-hidden checkerboard h-full w-full">
      <svg
        ref={svgRef}
        className={`w-full h-full touch-none ${activeTool === ToolType.NODE && hoverInsertPoint ? 'cursor-crosshair' : ''}`}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
      >
        <defs>
          <pattern id="grid" width="100" height="100" patternUnits="userSpaceOnUse">
             <path d="M 100 0 L 0 0 0 100" fill="none" stroke="#2a2a2a" strokeWidth="1" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#grid)" pointerEvents="none" />
        
        {paths.map(renderPath)}
        {renderRubberBand()}
        {renderControls()}
      </svg>
      
      {/* Hint overlay */}
      <div className="absolute bottom-4 left-4 pointer-events-none text-[#555] text-xs select-none">
         {activeTool === ToolType.PEN && "Click to add point. Drag to curve. Esc to finish."}
         {activeTool === ToolType.NODE && "Drag anchors/handles. Dbl-click anchor to toggle curve. Click path to add point."}
         {activeTool === ToolType.SELECT && "Click to select. Drag to move."}
      </div>
    </div>
  );
};

export default Canvas;