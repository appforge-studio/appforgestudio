import 'components.dart';
import 'package:dynamic_widget/dynamic_widget.dart';

class XD {
  init() {}
  XD() {
    DynamicWidgetBuilder.addParser(XDContainer());
    DynamicWidgetBuilder.addParser(XDText());
    DynamicWidgetBuilder.addParser(XDLayout());
  }
}

XD xd = XD();

