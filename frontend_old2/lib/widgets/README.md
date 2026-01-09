# Widget Components

This directory contains separated widget components for dragging and resizing functionality.

## Overview

The widgets have been split into separate components to provide more flexibility and better separation of concerns:

- **DraggableWidget**: Handles only dragging functionality
- **ResizableWidget**: Handles only resizing functionality

## Components

### DraggableWidget

A widget that can be dragged around the screen but cannot be resized.

**Features:**
- Pan gesture detection for dragging
- Smart guides integration for alignment
- Position tracking and updates
- Margin-based positioning

**Usage:**
```dart
DraggableWidget(
  widgetId: 'my-widget',
  width: 150,
  height: 100,
  margin: [50, 0, 50, 0], // [top, bottom, left, right]
  listener: myClickListener,
  child: Container(
    // Your widget content
  ),
)
```

### ResizableWidget

A widget that can be resized using corner and edge handles but cannot be dragged.

**Features:**
- Corner resize handles (red, 12x12)
- Edge resize handles (invisible, for better UX)
- Dimension overlay during resize
- Selection border with blue outline
- Minimum size constraints (50x50)

**Usage:**
```dart
ResizableWidget(
  widgetId: 'my-widget',
  width: 150,
  height: 100,
  margin: [50, 0, 50, 0],
  listener: myClickListener,
  child: Container(
    // Your widget content
  ),
)
```

## Integration with Container

The `XDContainer` widget automatically uses the appropriate widget based on selection state:

- **Selected widgets**: Use `ResizableWidget` for resizing functionality
- **Non-selected widgets**: Use `DraggableWidget` for dragging functionality

This provides a natural user experience where:
1. Users can drag non-selected widgets to move them
2. Selected widgets show resize handles and can be resized
3. The selection state determines which functionality is available

## Event Handling

All widgets use the `ClickListener` interface for event handling:

```dart
class MyClickListener implements ClickListener {
  @override
  void onClicked(String? event) {
    if (event != null) {
      final eventData = jsonDecode(event);
      switch (eventData['event']) {
        case 'onResize':
          // Handle resize event
          break;
        case 'onMarginChange':
          // Handle margin/drag event
          break;
      }
    }
  }
}
```

## Smart Guides Integration

The `DraggableWidget` includes smart guides functionality for automatic alignment with other widgets on the screen. This provides visual feedback and snapping behavior during dragging operations. 