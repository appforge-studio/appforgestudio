import 'package:appforge/widgets/color_picker/linear_picker.dart';
import 'package:appforge/widgets/color_picker/palette.dart';
import 'package:flutter/material.dart';
import '../models/types/color.dart';
import '../utilities/pallet.dart';

class PropertyColorField extends StatefulWidget {
  final String label;
  final XDColor value;
  final ValueChanged<XDColor> onChanged;
  final bool compact;
  final bool showLabel;
  final double? width;

  const PropertyColorField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.compact = false,
    this.showLabel = true,
    this.width,
  });

  @override
  State<PropertyColorField> createState() => _PropertyColorFieldState();
}

class _PropertyColorFieldState extends State<PropertyColorField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Local state for the editor
  late ColorType _selectedType;
  late HSVColor _solidHsvColor;
  late List<Color> _gradientColors;
  late List<double> _gradientStops;
  int _selectedStopIndex = 0;
  late Alignment _begin;
  late Alignment _end;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  void _initValues() {
    _selectedType = widget.value.type;
    _solidHsvColor = HSVColor.fromColor(widget.value.toColor());

    // Initialize gradient colors
    if (widget.value.value.length > 1) {
      _gradientColors = widget.value.toColors();

      // Initialize stops
      if (widget.value.stops.isNotEmpty &&
          widget.value.stops.length == _gradientColors.length) {
        _gradientStops = List.from(widget.value.stops);
      } else {
        _gradientStops = _calculateStops(_gradientColors.length);
      }
    } else {
      _gradientColors = [_solidHsvColor.toColor(), Colors.white];
      _gradientStops = [0.0, 1.0];
    }

    // Validate selection index
    if (_selectedStopIndex >= _gradientColors.length) {
      _selectedStopIndex = 0;
    }

    _begin = widget.value.begin;
    _end = widget.value.end;
  }

  @override
  void didUpdateWidget(PropertyColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // creating a new XDColor from internal state to check if we should update
      // purely to avoid resetting state while user is editing
      // requires comparing "value" content.
      // For simplicity, re-init if the *passed in* value changes externally.
      // Ideally we check if it matches our local "pending" state.
      _initValues();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _emitChange() {
    if (_selectedType == ColorType.solid) {
      final hexString = _colorToHex(_solidHsvColor.toColor());
      widget.onChanged(XDColor([hexString], type: ColorType.solid));
    } else {
      // Linear or Radial
      final hexColors = _gradientColors.map((c) => _colorToHex(c)).toList();
      widget.onChanged(
        XDColor(
          hexColors,
          type: _selectedType,
          stops: _gradientStops,
          begin: _begin,
          end: _end,
        ),
      );
    }
  }

  List<double> _calculateStops(int count) {
    if (count < 2) return [0.0, 1.0];
    final List<double> stops = [];
    for (int i = 0; i < count; i++) {
      stops.add(i / (count - 1));
    }
    return stops;
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    // Re-sync local state with current widget value just in case
    _initValues();

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Picker Popup
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-290, 35),
              child: Material(
                elevation: 8,
                color: Pallet.inside1,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StatefulBuilder(
                    builder: (context, setStateOverlay) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Type Switcher
                          Container(
                            height: 28,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Pallet.inside2,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                _buildTypeTab(
                                  ColorType.solid,
                                  "Solid",
                                  setStateOverlay,
                                ),
                                _buildTypeTab(
                                  ColorType.linear,
                                  "Linear",
                                  setStateOverlay,
                                ),
                                _buildTypeTab(
                                  ColorType.radial,
                                  "Radial",
                                  setStateOverlay,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Editor Content
                          if (_selectedType == ColorType.solid)
                            _buildSolidEditor(setStateOverlay)
                          else
                            _buildGradientEditor(setStateOverlay),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildTypeTab(
    ColorType type,
    String name,
    StateSetter setStateOverlay,
  ) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setStateOverlay(() {
            _selectedType = type;
            // When switching to gradient, ensure we have at least 2 colors
            if (_selectedType != ColorType.solid &&
                _gradientColors.length < 2) {
              _gradientColors = [_solidHsvColor.toColor(), Colors.white];
              _gradientStops = [0.0, 1.0];
              _selectedStopIndex = 0;
            }
          });
          _emitChange(); // Auto-apply on type change? User expectation: maybe.
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Pallet.inside3 : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white : Pallet.font2,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolidEditor(StateSetter setStateOverlay) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Color Area
            SizedBox(
              width:
                  320 -
                  82.0, // Available width (320) - H_Padding(24) - Spaces(18) - Sliders(40) = 238.
              height: 200,
              child: ColorPickerArea(_solidHsvColor, (hsv) {
                setStateOverlay(() => _solidHsvColor = hsv);
                _emitChange();
              }, PaletteType.hsv),
            ),
            const SizedBox(width: 10),
            // Vertical Sliders
            SizedBox(
              width: 20,
              height: 200,
              child: ColorPickerSlider(TrackType.hue, _solidHsvColor, (hsv) {
                setStateOverlay(() => _solidHsvColor = hsv);
                _emitChange();
              }, isVertical: true),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 200,
              child: ColorPickerSlider(TrackType.alpha, _solidHsvColor, (hsv) {
                setStateOverlay(() => _solidHsvColor = hsv);
                _emitChange();
              }, isVertical: true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Hex Input or other controls
        ColorPickerInput(
          _solidHsvColor.toColor(),
          (c) {
            setStateOverlay(() => _solidHsvColor = HSVColor.fromColor(c));
            _emitChange();
          },
          enableAlpha: true,
          embeddedText: true,
        ),
      ],
    );
  }

  Widget _buildGradientEditor(StateSetter setStateOverlay) {
    Color currentStopColor = _gradientColors.length > _selectedStopIndex
        ? _gradientColors[_selectedStopIndex]
        : Colors.transparent;

    return Column(
      children: [
        // Linear Picker (Preview bar + Stops)
        LinearColorPicker(
          colors: _gradientColors,
          stops: _gradientStops,
          selectedIndex: _selectedStopIndex,
          onColorsChanged: (c) {
            debugPrint('PropertyColorField: onColorsChanged');
            setStateOverlay(() => _gradientColors = c);
            _emitChange();
          },
          onStopsChanged: (s) {
            debugPrint('PropertyColorField: onStopsChanged: $s');
            setStateOverlay(() => _gradientStops = s);
            _emitChange();
          },
          onSelectionChanged: (index) {
            debugPrint('PropertyColorField: onSelectionChanged: $index');
            setStateOverlay(() => _selectedStopIndex = index);
          },
        ),

        const SizedBox(height: 12),

        // Color Picker for the selected stop
        // We reuse the solid editor parts but bind them to the selected stop color
        _buildStopColorEditor(currentStopColor, setStateOverlay),

        // Remove Stop Button
        if (_gradientColors.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Spacer(),
                GestureDetector(
                  onTap: () {
                    setStateOverlay(() {
                      _gradientColors.removeAt(_selectedStopIndex);
                      _gradientStops.removeAt(_selectedStopIndex);
                      if (_selectedStopIndex >= _gradientColors.length) {
                        _selectedStopIndex = _gradientColors.length - 1;
                      }
                    });
                    _emitChange();
                  },
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Pallet.font2,
                  ),
                ),
              ],
            ),
          ),

        Divider(color: Pallet.inside2, height: 16),

        // Direction / Alignment
        if (_selectedType == ColorType.linear)
          _buildLinearControls(setStateOverlay),
      ],
    );
  }

  Widget _buildStopColorEditor(Color color, StateSetter setStateOverlay) {
    HSVColor hsv = HSVColor.fromColor(color);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Color Area
            SizedBox(
              width: 320 - 82.0,
              height: 160, // Slightly smaller to fit everything?
              child: ColorPickerArea(hsv, (newHsv) {
                _updateSelectedStopColor(newHsv.toColor(), setStateOverlay);
              }, PaletteType.hsv),
            ),
            const SizedBox(width: 10),
            // Vertical Sliders
            Column(
              children: [
                SizedBox(
                  width: 20,
                  height: 160,
                  child: ColorPickerSlider(TrackType.hue, hsv, (newHsv) {
                    _updateSelectedStopColor(newHsv.toColor(), setStateOverlay);
                  }, isVertical: true),
                ),
              ],
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              height: 160,
              child: ColorPickerSlider(TrackType.alpha, hsv, (newHsv) {
                _updateSelectedStopColor(newHsv.toColor(), setStateOverlay);
              }, isVertical: true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Hex Input
        ColorPickerInput(
          color,
          (c) {
            _updateSelectedStopColor(c, setStateOverlay);
          },
          enableAlpha: true,
          embeddedText: true,
        ),
      ],
    );
  }

  void _updateSelectedStopColor(Color c, StateSetter setStateOverlay) {
    setStateOverlay(() {
      if (_selectedStopIndex < _gradientColors.length) {
        _gradientColors[_selectedStopIndex] = c;
      }
    });
    _emitChange();
  }

  Widget _buildLinearControls(StateSetter setStateOverlay) {
    // Simple 8-point direction grid or dropdown.
    // Let's use valid LinearGradient alignments.

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Direction",
              style: TextStyle(color: Pallet.font2, fontSize: 11),
            ),
            // Simple Rotate Icon or something?
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 5,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          children: [
            _buildDirBtn(
              Alignment.topCenter,
              Alignment.bottomCenter,
              Icons.arrow_downward,
              setStateOverlay,
            ),
            _buildDirBtn(
              Alignment.bottomCenter,
              Alignment.topCenter,
              Icons.arrow_upward,
              setStateOverlay,
            ),
            _buildDirBtn(
              Alignment.centerLeft,
              Alignment.centerRight,
              Icons.arrow_forward,
              setStateOverlay,
            ),
            _buildDirBtn(
              Alignment.centerRight,
              Alignment.centerLeft,
              Icons.arrow_back,
              setStateOverlay,
            ),
            _buildDirBtn(
              Alignment.topLeft,
              Alignment.bottomRight,
              Icons.south_east,
              setStateOverlay,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDirBtn(
    Alignment b,
    Alignment e,
    IconData icon,
    StateSetter setStateOverlay,
  ) {
    final bool isSelected = _begin == b && _end == e;
    return GestureDetector(
      onTap: () {
        setStateOverlay(() {
          _begin = b;
          _end = e;
        });
        _emitChange();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Pallet.inside3 : Pallet.inside2,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : Pallet.font1,
        ),
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    // If gradient, we might want to show a GradientBox in the preview instead of solid color.
    BoxDecoration previewDecoration;
    if (widget.value.type == ColorType.solid) {
      previewDecoration = BoxDecoration(
        color: widget.value.toColor(),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Pallet.divider),
      );
    } else {
      // Gradient Preview in the small box
      if (widget.value.type == ColorType.linear) {
        previewDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: widget.value.toColors(),
            begin: widget.value.begin,
            end: widget.value.end,
            stops: widget.value.stops.isEmpty ? null : widget.value.stops,
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Pallet.divider),
        );
      } else {
        // Radial
        previewDecoration = BoxDecoration(
          gradient: RadialGradient(
            colors: widget.value.toColors(),
            stops: widget.value.stops.isEmpty ? null : widget.value.stops,
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Pallet.divider),
        );
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compact && widget.showLabel)
          SizedBox(
            width: 80,
            child: Text(
              "${widget.label}:",
              style: TextStyle(fontSize: 13, color: Pallet.font1),
            ),
          ),
        if (!widget.compact && widget.showLabel) const SizedBox(width: 5),

        // Wrapped functional color box
        CompositedTransformTarget(
          link: _layerLink,
          child: widget.width != null
              ? GestureDetector(
                  onTap: _showOverlay,
                  child: Container(
                    width: widget.width,
                    height: 30,
                    decoration: previewDecoration,
                  ),
                )
              : Expanded(
                  child: GestureDetector(
                    onTap: _showOverlay,
                    child: Container(height: 30, decoration: previewDecoration),
                  ),
                ),
        ),
      ],
    );
  }
}
