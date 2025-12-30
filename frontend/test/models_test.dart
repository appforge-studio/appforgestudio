import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:appforge/models/enums.dart';
import 'package:appforge/components/component_factory.dart';
import 'package:appforge/controllers/canvas_controller.dart';

void main() {
  group('Component Models', () {
    test('ContainerComponent serialization round-trip', () {
      final original = ComponentFactory.createComponent(
        ComponentType.container,
        10.0,
        20.0,
      );
      final json = original.toJson();
      final restored = ComponentFactory.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.id, equals(original.id));
    });

    test('TextComponent serialization round-trip', () {
      final original = ComponentFactory.createComponent(
        ComponentType.text,
        15.0,
        25.0,
      );
      final json = original.toJson();
      final restored = ComponentFactory.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.id, equals(original.id));
    });

    test('ImageComponent serialization round-trip', () {
      final original = ComponentFactory.createComponent(
        ComponentType.image,
        30.0,
        40.0,
      );
      final json = original.toJson();
      final restored = ComponentFactory.fromJson(json);

      expect(restored.type, equals(original.type));
      expect(restored.x, equals(original.x));
      expect(restored.y, equals(original.y));
      expect(restored.id, equals(original.id));
    });

    test('JSON schema generation', () {
      final container = ComponentFactory.createComponent(
        ComponentType.container,
        0.0,
        0.0,
      );
      final text = ComponentFactory.createComponent(
        ComponentType.text,
        0.0,
        0.0,
      );
      final image = ComponentFactory.createComponent(
        ComponentType.image,
        0.0,
        0.0,
      );

      final containerSchema = ComponentFactory.toJsonSchema(container);
      final textSchema = ComponentFactory.toJsonSchema(text);
      final imageSchema = ComponentFactory.toJsonSchema(image);

      expect(containerSchema['type'], equals('container'));
      expect(textSchema['type'], equals('text'));
      expect(imageSchema['type'], equals('sized_box'));

      expect(containerSchema['args'], isA<Map<String, dynamic>>());
      expect(textSchema['args'], isA<Map<String, dynamic>>());
      expect(imageSchema['args'], isA<Map<String, dynamic>>());
    });
  });

  group('Component Repositioning', () {
    late CanvasController controller;

    setUp(() {
      Get.testMode = true;
      controller = CanvasController();
    });

    tearDown(() {
      Get.reset();
    });

    test('updateComponentPosition constrains within canvas boundaries', () {
      // Add a component to the canvas
      final component = ComponentFactory.createComponent(
        ComponentType.container,
        50.0,
        50.0,
      );
      controller.addComponent(component);

      // Try to move component outside canvas boundaries
      controller.updateComponentPosition(component.id, -10.0, -10.0);

      final updatedComponent = controller.getComponentById(component.id);
      expect(updatedComponent!.x, equals(0.0)); // Should be constrained to 0
      expect(updatedComponent.y, equals(0.0)); // Should be constrained to 0
    });

    test('updateComponentPosition updates component coordinates', () {
      // Add a component to the canvas
      final component = ComponentFactory.createComponent(
        ComponentType.container,
        50.0,
        50.0,
      );
      controller.addComponent(component);

      // Move component to new valid position
      controller.updateComponentPosition(component.id, 100.0, 150.0);

      final updatedComponent = controller.getComponentById(component.id);
      expect(updatedComponent!.x, equals(100.0));
      expect(updatedComponent.y, equals(150.0));
    });

    test('setDragState sets dragging state', () {
      // Add a component to the canvas
      final component = ComponentFactory.createComponent(
        ComponentType.container,
        50.0,
        50.0,
      );
      controller.addComponent(component);

      // Start dragging the component
      controller.setDragState(component.id, true);

      expect(controller.isDraggingComponent, isTrue);
      expect(controller.draggingComponentId, equals(component.id));
    });

    test('setDragState resets dragging state', () {
      // Add a component to the canvas
      final component = ComponentFactory.createComponent(
        ComponentType.container,
        50.0,
        50.0,
      );
      controller.addComponent(component);

      // Start and end dragging
      controller.setDragState(component.id, true);
      controller.setDragState(component.id, false);

      expect(controller.isDraggingComponent, isFalse);
      expect(controller.draggingComponentId, equals(''));
    });

    test('updateComponentPosition works during drag', () {
      // Add a component to the canvas
      final component = ComponentFactory.createComponent(
        ComponentType.container,
        50.0,
        50.0,
      );
      controller.addComponent(component);

      // Start dragging and update position
      controller.setDragState(component.id, true);
      controller.updateComponentPosition(component.id, 100.0, 150.0);

      final updatedComponent = controller.getComponentById(component.id);
      expect(updatedComponent!.x, equals(100.0));
      expect(updatedComponent.y, equals(150.0));
    });
  });
}
