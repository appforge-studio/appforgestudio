import 'dart:math';
import '../globals.dart';
import '../studio/properties.dart';
// import '../xd/build.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controls.dart';
import 'simulator.dart';
import 'widgets/tabs.dart';
import 'widgets/database_page.dart';
import '../providers/providers.dart';

class Studio extends StatefulWidget {
  const Studio({Key? key}) : super(key: key);

  @override
  State<Studio> createState() => _StudioState();
}

class _StudioState extends State<Studio> {
  final AppTabController appTabController = Get.find<AppTabController>();
  late final TransformationController controller;
  final GlobalKey simKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    controller = TransformationController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallet.background,
      body: GetBuilder<AppTabController>(
        builder: (tabController) {
          final selectedTab = tabController.selectedTab;
          final isDatabaseMode = selectedTab == "database";
          
          return Row(
            children: [
              // Conditionally show Controls panel
              if (!isDatabaseMode) const Controls(),
              
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    const Tabs(),
                    const SizedBox(height: 5),
                    Expanded(
                      child: GetBuilder<AppTabController>(
                        builder: (tabController) {
                          final selectedTab = tabController.selectedTab;
                          
                          if (selectedTab == "database") {
                            return DatabasePage();
                          }
                          
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final RenderBox? box =
                                    simKey.currentContext?.findRenderObject()
                                        as RenderBox?;
                                if (box == null) return;

                                final Size vpSize = constraints.biggest;
                                final Size chSize = box.size;

                                // Compute uniform scale to fit child
                                final double scale = min(
                                  vpSize.width / chSize.width,
                                  vpSize.height / chSize.height,
                                );

                                // Compute offsets after scaling to center
                                final double scaledW = chSize.width * scale;
                                final double scaledH = chSize.height * scale;
                                final double offX = (vpSize.width - scaledW) / 2;
                                final double offY = (vpSize.height - scaledH) / 2;

                                final Matrix4 m = Matrix4.identity()
                                  ..scale(scale)
                                  ..translate(offX / scale, offY / scale);

                                controller.value = m;
                              });

                              return InteractiveViewer(
                                transformationController: controller,
                                panEnabled: true,
                                scaleEnabled: true,
                                minScale: 0.1,
                                maxScale: 2.0,
                                boundaryMargin: const EdgeInsets.all(1000),
                                constrained: false,
                                child: Simulator(key: simKey),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Conditionally show Properties panel
              if (!isDatabaseMode) const Properties(),
            ],
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: buildComponents,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
