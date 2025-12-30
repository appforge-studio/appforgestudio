import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Widget')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Testing json_dynamic_widget'),
            const SizedBox(height: 20),
            _buildTestJsonWidget(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('🧪 Test button pressed');
              },
              child: const Text('Test Button'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestJsonWidget() {
    return Builder(
      builder: (BuildContext context) {
        final jsonSchema = {
          'type': 'container',
          'args': {
            'width': 100.0,
            'height': 100.0,
            'decoration': {
              'color': '#FF2196F3',
              'borderRadius': 8.0,
            },
            'child': {
              'type': 'center',
              'args': {
                'child': {
                  'type': 'text',
                  'args': {
                    'data': 'Test',
                    'style': {
                      'color': '#FFFFFFFF',
                      'fontSize': 16.0,
                    },
                  },
                },
              },
            },
          },
        };

        try {
          debugPrint('🧪 Creating JsonWidgetData with schema: $jsonSchema');
          
          final widgetData = JsonWidgetData.fromDynamic(
            jsonSchema,
            registry: JsonWidgetRegistry.instance,
          );

          final widget = widgetData.build(
            context: context,
            registry: JsonWidgetRegistry.instance,
          );

          debugPrint('🧪 JsonWidget built successfully');
          return widget ?? const Text('Failed to build widget');
        } catch (e, stackTrace) {
          debugPrint('🧪 Error building JsonWidget: $e');
          debugPrint('🧪 Stack trace: $stackTrace');
          return Container(
            width: 100,
            height: 100,
            color: Colors.red,
            child: const Center(
              child: Text('Error', style: TextStyle(color: Colors.white)),
            ),
          );
        }
      },
    );
  }
}