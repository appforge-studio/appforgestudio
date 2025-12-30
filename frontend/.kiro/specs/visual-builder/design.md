# Visual Builder Design Document

## Overview

The Visual Builder is a Flutter application that provides a drag-and-drop interface for creating mobile UI layouts. The system combines Flutter's native drag-and-drop capabilities with json_dynamic_widget for dynamic component rendering and GetX for reactive state management. The architecture follows a clean separation between the component library, canvas management, and state persistence layers.

## Architecture

The application follows a layered architecture with clear separation of concerns:

```
┌───────────────────────────────────────────────────────────┐
│                    UI Layer                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────┐  │
│  │ Component   │ │   Canvas    │ │   Property Editor   │  │
│  │   Panel     │ │             │ │                     │  │
│  └─────────────┘ └─────────────┘ └─────────────────────┘  │
└───────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│           Controller Layer              │
│  ┌─────────────────┐ ┌─────────────────┐│
│  │ Canvas Controller│ │Component Factory││
│  └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  ┌─────────────────┐ ┌─────────────────┐│
│  │ Component Model │ │  JSON Schemas   ││
│  └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────┘
```

## Components and Interfaces

### Core Components

**CanvasController (GetX Controller)**
- Manages CanvasState with reactive updates
- Handles component CRUD operations using typed component classes
- Provides methods for component selection and deselection
- Manages canvas dimensions and boundary constraints
- Implements SelectionHandler interface

**ComponentFactory (Singleton)**
- Creates typed component instances (ContainerComponent, TextComponent, ImageComponent)
- Handles JSON serialization/deserialization for each component type
- Manages default property instances for each component type
- Implements ComponentFactory interface

**PropertyEditorController (GetX Controller)**
- Manages PropertyEditorState with reactive updates
- Handles property changes for different component types
- Provides type-safe property editing methods
- Coordinates with CanvasController for component updates

**ComponentPanel Widget**
- Displays draggable representations of each ComponentType
- Implements DragDropHandler for drag source functionality
- Uses ComponentFactory to create preview instances
- Provides visual feedback during drag operations

**DesignCanvas Widget**
- Renders components using their jsonSchema properties
- Implements DragDropHandler for drop target functionality
- Handles component selection through SelectionHandler
- Manages component positioning with boundary constraints
- Uses JSON_Dynamic_Widget for component rendering

**PropertyEditor Widget**
- Displays type-specific property editing forms
- Uses PropertyEditor<T> implementations for each component type
- Updates component properties through PropertyEditorController
- Provides real-time preview of property changes

**Component-Specific Property Editors**
- ContainerPropertyEditor implements PropertyEditor<ContainerProperties>
- TextPropertyEditor implements PropertyEditor<TextProperties>
- ImagePropertyEditor implements PropertyEditor<ImageProperties>
- Each provides specialized input fields for their property type

### Key Interfaces

```dart
abstract class PropertyEditor<T> {
  Widget buildPropertyFields(T properties, Function(T) onChanged);
  T getDefaultProperties();
  bool validateProperties(T properties);
}

abstract class ComponentFactory {
  ComponentModel createComponent(ComponentType type, double x, double y);
  ComponentModel fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJsonSchema(ComponentModel component);
}

abstract class DragDropHandler {
  void onDragStart(ComponentType type);
  void onDragUpdate(Offset position);
  void onDragEnd(Offset position, ComponentModel? component);
}

abstract class SelectionHandler {
  void onComponentSelected(ComponentModel component);
  void onComponentDeselected();
  void onComponentPropertiesChanged(ComponentModel component);
}
```

## Data Models

### Base Component Model
```dart
abstract class ComponentModel {
  final String id;
  final ComponentType type;
  double x;
  double y;
  
  ComponentModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
  });
  
  Map<String, dynamic> toJson();
  Map<String, dynamic> get jsonSchema;
  ComponentModel copyWith({double? x, double? y});
}
```

### Property Classes
```dart
class ContainerProperties {
  final double width;
  final double height;
  final Color backgroundColor;
  final double borderRadius;
  final EdgeInsets padding;
  final Border? border;
  
  ContainerProperties({
    this.width = 100,
    this.height = 100,
    this.backgroundColor = Colors.blue,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(8.0),
    this.border,
  });
  
  ContainerProperties copyWith({
    double? width,
    double? height,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsets? padding,
    Border? border,
  });
  
  Map<String, dynamic> toJson();
}

class TextProperties {
  final String content;
  final double fontSize;
  final Color color;
  final TextAlign alignment;
  final FontWeight fontWeight;
  final String fontFamily;
  
  TextProperties({
    this.content = 'Sample Text',
    this.fontSize = 16.0,
    this.color = Colors.black,
    this.alignment = TextAlign.left,
    this.fontWeight = FontWeight.normal,
    this.fontFamily = 'Roboto',
  });
  
  TextProperties copyWith({
    String? content,
    double? fontSize,
    Color? color,
    TextAlign? alignment,
    FontWeight? fontWeight,
    String? fontFamily,
  });
  
  Map<String, dynamic> toJson();
}

class ImageProperties {
  final String source;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  
  ImageProperties({
    this.source = 'https://via.placeholder.com/150',
    this.width = 150,
    this.height = 150,
    this.fit = BoxFit.cover,
    this.borderRadius = 0.0,
  });
  
  ImageProperties copyWith({
    String? source,
    double? width,
    double? height,
    BoxFit? fit,
    double? borderRadius,
  });
  
  Map<String, dynamic> toJson();
}
```

### Component Implementations
```dart
class ContainerComponent extends ComponentModel {
  final ContainerProperties properties;
  
  ContainerComponent({
    required String id,
    required double x,
    required double y,
    required this.properties,
  }) : super(id: id, type: ComponentType.container, x: x, y: y);
  
  @override
  Map<String, dynamic> get jsonSchema => {
    'type': 'Container',
    'args': {
      'width': properties.width,
      'height': properties.height,
      'decoration': {
        'color': properties.backgroundColor.value,
        'borderRadius': properties.borderRadius,
      },
      'padding': properties.padding.toJson(),
    },
  };
  
  ContainerComponent copyWithProperties(ContainerProperties newProperties) {
    return ContainerComponent(
      id: id,
      x: x,
      y: y,
      properties: newProperties,
    );
  }
}

class TextComponent extends ComponentModel {
  final TextProperties properties;
  
  TextComponent({
    required String id,
    required double x,
    required double y,
    required this.properties,
  }) : super(id: id, type: ComponentType.text, x: x, y: y);
  
  @override
  Map<String, dynamic> get jsonSchema => {
    'type': 'Text',
    'args': {
      'data': properties.content,
      'style': {
        'fontSize': properties.fontSize,
        'color': properties.color.value,
        'fontWeight': properties.fontWeight.index,
        'fontFamily': properties.fontFamily,
      },
      'textAlign': properties.alignment.index,
    },
  };
  
  TextComponent copyWithProperties(TextProperties newProperties) {
    return TextComponent(
      id: id,
      x: x,
      y: y,
      properties: newProperties,
    );
  }
}

class ImageComponent extends ComponentModel {
  final ImageProperties properties;
  
  ImageComponent({
    required String id,
    required double x,
    required double y,
    required this.properties,
  }) : super(id: id, type: ComponentType.image, x: x, y: y);
  
  @override
  Map<String, dynamic> get jsonSchema => {
    'type': 'Image',
    'args': {
      'src': properties.source,
      'width': properties.width,
      'height': properties.height,
      'fit': properties.fit.index,
    },
  };
  
  ImageComponent copyWithProperties(ImageProperties newProperties) {
    return ImageComponent(
      id: id,
      x: x,
      y: y,
      properties: newProperties,
    );
  }
}
```

### State Classes
```dart
class CanvasState {
  final List<ComponentModel> components;
  final Size canvasSize;
  final ComponentModel? selectedComponent;
  final bool isDragging;
  final bool isPropertyEditorVisible;
  
  CanvasState({
    this.components = const [],
    this.canvasSize = const Size(375, 812), // iPhone 12 size
    this.selectedComponent,
    this.isDragging = false,
    this.isPropertyEditorVisible = false,
  });
  
  CanvasState copyWith({
    List<ComponentModel>? components,
    Size? canvasSize,
    ComponentModel? selectedComponent,
    bool? isDragging,
    bool? isPropertyEditorVisible,
  });
}

class PropertyEditorState {
  final ComponentModel? selectedComponent;
  final bool isVisible;
  
  PropertyEditorState({
    this.selectedComponent,
    this.isVisible = false,
  });
  
  PropertyEditorState copyWith({
    ComponentModel? selectedComponent,
    bool? isVisible,
  });
}
```

### Enums
```dart
enum ComponentType {
  container,
  text,
  image,
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Property 1: Component panel draggability
*For any* component displayed in the Component_Panel, that component should have draggable properties enabled
**Validates: Requirements 1.3**

Property 2: Drag operation visual feedback
*For any* component drag operation from the Component_Panel, the system should provide visual feedback indicating the drag is active
**Validates: Requirements 2.1**

Property 3: Canvas drop zone indicators
*For any* component being dragged over the Canvas, the system should display drop zone indicators
**Validates: Requirements 2.2**

Property 4: Component creation on drop
*For any* valid drop location on the Canvas, dropping a component should create a new component instance at that location
**Validates: Requirements 2.3**

Property 5: JSON generation on component drop
*For any* component type dropped onto the Canvas, the system should generate valid JSON_Dynamic_Widget configuration
**Validates: Requirements 2.4**

Property 6: State update on component addition
*For any* component successfully added to the Canvas, the GetX state should be updated to reflect the new component
**Validates: Requirements 2.5**

Property 7: Canvas centering
*For any* screen size, the Canvas should be centered in the available screen space
**Validates: Requirements 3.2**

Property 8: Component boundary constraints
*For any* component drop attempt, the system should constrain the component within Canvas boundaries
**Validates: Requirements 3.3**

Property 9: Placed component draggability
*For any* placed component on the Canvas, tapping it should make it draggable within the Canvas
**Validates: Requirements 4.1**

Property 10: Real-time coordinate updates
*For any* component being dragged, the system should update its x and y coordinates in real-time
**Validates: Requirements 4.2**

Property 11: Repositioning visual feedback
*For any* component being repositioned, the system should provide visual feedback showing the new position
**Validates: Requirements 4.3**

Property 12: State update on repositioning
*For any* component repositioning completion, the GetX state should be updated with the new coordinates
**Validates: Requirements 4.4**

Property 13: JSON update on coordinate change
*For any* component coordinate change, the JSON_Dynamic_Widget configuration should be updated accordingly
**Validates: Requirements 4.5**

Property 14: UI reactivity on state change
*For any* Canvas state update, all dependent UI elements should be notified through GetX reactivity
**Validates: Requirements 5.2**

Property 15: Position persistence
*For any* component position change, the changes should be persisted through GetX state management
**Validates: Requirements 5.3**

Property 16: Property editor display on selection
*For any* component selected on the Canvas, the system should display the Property_Editor on the right side
**Validates: Requirements 6.1**

Property 17: Component-specific property display
*For any* component type displayed in the Property_Editor, all editable properties for that type should be shown
**Validates: Requirements 6.2**

Property 18: Real-time property updates
*For any* property value changed in the Property_Editor, the component should be updated immediately on the Canvas
**Validates: Requirements 6.3**

Property 19: Type-specific property fields
*For any* component type selected, the Property_Editor should display the appropriate property fields for that type
**Validates: Requirements 6.5**

Property 20: JSON schema generation
*For any* component added to the Canvas, the system should generate valid JSON_Dynamic_Widget schema
**Validates: Requirements 7.1**

Property 21: JSON update on property change
*For any* component property change, the corresponding JSON configuration should be updated
**Validates: Requirements 7.2**

Property 22: JSON_Dynamic_Widget rendering
*For any* component on the Canvas, the system should use JSON_Dynamic_Widget to create the visual representation
**Validates: Requirements 7.3**

Property 23: JSON specification compliance
*For any* JSON configuration created, it should conform to JSON_Dynamic_Widget specifications
**Validates: Requirements 7.4**

Property 24: Serialization round-trip
*For any* component, serializing then deserializing should produce an equivalent component that renders correctly
**Validates: Requirements 7.5**

## Error Handling

### Drag and Drop Errors
- Invalid drop locations outside Canvas boundaries should be rejected gracefully
- Failed component creation should not corrupt the Canvas state
- Drag operations interrupted by system events should reset cleanly

### JSON Configuration Errors
- Invalid JSON schemas should be caught and logged with fallback to default configurations
- Malformed component properties should be sanitized or reset to defaults
- JSON_Dynamic_Widget parsing errors should not crash the application

### State Management Errors
- GetX controller initialization failures should be handled with appropriate fallbacks
- State corruption should trigger automatic state reset mechanisms
- Concurrent state modifications should be properly synchronized

## Testing Strategy

The testing approach combines unit testing for specific functionality with property-based testing for universal behaviors:

### Unit Testing
- Component panel initialization and display
- Canvas dimensions and positioning
- GetX controller setup and initialization
- JSON schema generation for specific component types
- Drag and drop event handling for specific scenarios

### Property-Based Testing
The system will use the `test` package with custom property testing utilities for Flutter. Each property-based test will run a minimum of 100 iterations to ensure comprehensive coverage.

**Property-based testing requirements:**
- Each property test will be tagged with comments referencing the design document property
- Tests will use format: '**Feature: visual-builder, Property {number}: {property_text}**'
- Component generation will create valid instances with randomized but realistic properties
- Position generation will respect Canvas boundaries and valid coordinate ranges
- JSON validation will verify both structure and JSON_Dynamic_Widget compatibility

**Key property test areas:**
- Component drag and drop operations across all component types and positions
- State management reactivity across various state change scenarios  
- JSON serialization/deserialization round-trips for all component configurations
- Boundary constraint enforcement for edge cases and invalid positions
- UI feedback consistency across different interaction patterns

### Integration Testing
- End-to-end drag and drop workflows
- State persistence across application lifecycle
- JSON_Dynamic_Widget integration with GetX state management
- Multi-component interactions and positioning

The dual testing approach ensures both concrete functionality works correctly (unit tests) and universal properties hold across all valid inputs (property tests), providing comprehensive correctness validation.