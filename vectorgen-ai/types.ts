export interface Point {
  x: number;
  y: number;
}

export interface ControlPoint extends Point {
  type: 'anchor' | 'handle-in' | 'handle-out';
  parentId?: string; // ID of the anchor this handle belongs to
}

export interface PathNode {
  id: string;
  x: number;
  y: number;
  handleIn: Point; // Relative to x,y if we were strict, but let's use absolute coords for simplicity in this demo
  handleOut: Point;
  isCurve: boolean; // if false, handles collapse to anchor
}

export interface VectorPath {
  id: string;
  name: string;
  nodes: PathNode[];
  closed: boolean;
  fill: string; // hex or 'none'
  stroke: string; // hex
  strokeWidth: number;
  isVisible: boolean;
  isLocked: boolean;
}

export enum ToolType {
  SELECT = 'SELECT',
  PEN = 'PEN',
  NODE = 'NODE', // Direct selection
}

export type DragMode = 'ANCHOR' | 'HANDLE_IN' | 'HANDLE_OUT' | 'WHOLE_PATH' | null;

export interface DragState {
  isDragging: boolean;
  mode: DragMode;
  targetId: string | null; // Node ID or Path ID
  subTargetId?: string | null; // Specifically for handles
  startPoint: Point;
  originalNodes: PathNode[]; // Snapshot for delta calculations
}