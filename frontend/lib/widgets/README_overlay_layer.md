# Component Overlay System

This implementation creates a clean separation between visual components and their interaction handling by introducing a unified overlay management system.

## Architecture

### ComponentOverlayManager
- **Purpose**: Unified manager for all component interactions
- **Location**: `lib/utilities/component_overlay_manager.dart`
- **Features**:
  - Centralized cursor management
  - Drag and resize handling
  - Selection indicators
  - Edge detection zones
  - Consolidated interaction logic

### ComponentOverlayLayer
- **Purpose**: Sits on top of the canvas components and delegates to the manager
- **Location**: `lib/widgets/component_overlay_layer.dart`
- **Features**:
  - Invisible interaction areas that align with components below
  - Uses ComponentOverlayManager for all interactions
  - Clean interface between canvas and interaction logic

### Updated DesignCanvas
- **Purpose**: Renders visual components only, no interaction handling
- **Location**: `lib/widgets/design_canvas.dart`
- **Changes**:
  - Removed complex interaction logic from component widgets
  - Components are now purely visual (rendered via JSON schema)
  - Overlay layer handles all user interactions
  - Uses ComponentOverlayManager for cursor management

## Key Benefits

1. **Clean Separation**: Visual rendering is separate from interaction logic
2. **Better Performance**: No complex gesture detectors on every component
3. **Easier Maintenance**: Interaction logic is centralized in the overlay
4. **Flexible Interactions**: Easy to add new interaction types without modifying visual components
5. **Consistent Behavior**: All components use the same interaction patterns

## How It Works

### Layer Stack (bottom to top):
1. **Canvas Background**: Grid guides and drop indicators
2. **Visual Components**: Pure visual rendering via JSON schema
3. **Overlay Layer**: Invisible interaction widgets aligned with components

### Interaction Flow:
1. User interacts with invisible overlay widgets
2. Overlay detects the interaction type (drag, resize, select)
3. Controller updates component state
4. Visual components re-render based on new state
5. Overlay updates interaction handles and cursors

## Usage

The overlay layer is automatically included in the DesignCanvas:

```dart
Stack(
  children: [
    // Canvas guides
    _buildCanvasGuides(canvasSize),
    
    // Visual components (no interactions)
    ...components.map(_buildVisualComponentWidget),
    
    // Overlay layer (all interactions)
    ComponentOverlayLayer(canvasSize: canvasSize),
  ],
)
```

## Demo

Use the "Overlay Demo" button in the app to see the overlay layer in action:
- Drag components from the palette to the canvas
- Click to select components (blue border appears)
- Drag selected components around the canvas
- Resize components using the corner/edge handles
- Notice smooth cursor changes and visual feedback

## Removed Duplicate Functionality

### Consolidated Managers
- **Removed**: `ResizeCursorManager` - cursor logic moved to ComponentOverlayManager
- **Removed**: `ResizeHandleManager` - resize handling moved to ComponentOverlayManager
- **Unified**: All interaction logic now in single ComponentOverlayManager

### Benefits of Consolidation
- Single source of truth for all interactions
- Reduced code duplication
- Easier maintenance and debugging
- Consistent behavior across all interaction types
- Simplified dependency management

## Implementation Details

### Unified Cursor Management
- Single `getCursor()` method handles all cursor types
- Supports resize handles, drag states, and canvas interactions
- Consistent cursor behavior across the application

### Centralized Interaction Handling
- All drag, resize, and selection logic in one place
- Consistent event handling patterns
- Shared constants and styling
- Unified boundary constraint logic

### Invisible Interaction Areas
- Each component gets an invisible overlay widget
- Positioned exactly over the visual component
- Captures all mouse/touch events
- Provides appropriate cursor feedback

### Resize Handles
- Visible only when component is selected
- Corner handles for diagonal resizing
- Edge handles for single-axis resizing
- Invisible edge detection zones for cursor feedback

### Selection Feedback
- Blue border around selected components
- Animated selection indicators
- Visual feedback during drag/resize operations

### Boundary Constraints
- Components cannot be dragged outside canvas bounds
- Resize operations respect minimum sizes
- Automatic position clamping during interactions