# Smart Guides Implementation

## Overview
Smart Guides are dynamic, temporary indicators that appear when dragging widgets in the simulator. They help align widgets by showing when edges or centers line up with other objects on the canvas.

## Features
- **Edge Alignment**: Shows blue lines when widget edges align with other widgets
- **Center Alignment**: Shows green lines with diamond indicators when widget centers align
- **Snap-to-Alignment**: Automatically snaps widgets to alignment positions when guides are active
- **Real-time Detection**: Continuously detects alignments during dragging

## Implementation Details

### Core Components

1. **SmartGuidesProvider** (`lib/providers/smart_guides.dart`)
   - Manages the state of active smart guides
   - Stores widget positions for alignment detection
   - Provides methods to show/hide guides

2. **SmartGuidesService** (`lib/utils/smart_guides_service.dart`)
   - Contains logic for detecting alignments
   - Handles snap-to-alignment calculations
   - Converts between margin and position formats

3. **SmartGuidesOverlay** (`lib/widgets/smart_guides.dart`)
   - Renders the visual guide lines
   - Shows different styles for edge vs center alignments
   - Positioned as an overlay on the simulator canvas

4. **Enhanced ResizableWidget** (`lib/widgets/resizable_widget.dart`)
   - Integrates with smart guides during dragging
   - Updates widget positions in real-time
   - Triggers alignment detection and snapping

### How It Works

1. **Position Tracking**: When widgets are built or moved, their positions are registered in the `widgetPositionsProvider`

2. **Alignment Detection**: During dragging, the system compares the dragged widget's position with all other widgets to detect:
   - Left edge alignments
   - Right edge alignments  
   - Top edge alignments
   - Bottom edge alignments
   - Vertical center alignments
   - Horizontal center alignments

3. **Visual Feedback**: When alignments are detected, guide lines are displayed:
   - Blue lines for edge alignments
   - Green lines with diamond indicators for center alignments

4. **Snap-to-Alignment**: If guides are active, the dragged widget automatically snaps to the alignment position

### Usage

1. **Enable Smart Guides**: The feature is automatically enabled when dragging widgets
2. **Drag Widgets**: Click and drag any widget in the simulator
3. **See Alignments**: Blue and green guide lines will appear when alignments are detected
4. **Snap to Position**: Release the widget to snap it to the aligned position

### Configuration

- **Snap Threshold**: Set to 8 pixels in `SmartGuidesService._snapThreshold`
- **Guide Colors**: Blue for edges, green for centers
- **Guide Styles**: 2px lines with shadow effects

### Integration Points

- **Simulator**: Includes the `SmartGuidesOverlay` widget
- **Container Widget**: Registers positions when built
- **ResizableWidget**: Handles dragging and alignment detection
- **Event System**: Updates positions when margins change

## Future Enhancements

- **Distance Indicators**: Show distance measurements between widgets
- **Grid Snapping**: Snap to grid lines
- **Custom Thresholds**: User-configurable snap distances
- **Guide Preferences**: Toggle different types of guides
- **Performance Optimization**: Optimize for large numbers of widgets 