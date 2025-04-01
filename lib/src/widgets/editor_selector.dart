import 'package:flutter/material.dart';
import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';

enum EditorMode {
  color,
  emojis,
  layout,
}

class EditorSelector extends StatefulWidget {
  final EditorMode selectedMode;
  final ValueChanged<EditorMode> onModeChanged;
  final ValueChanged<Color>? onColorChanged;
  final ValueChanged<String>? onEmojiChanged;
  final ValueChanged<double>? onDensityChanged;
  final ValueChanged<double>? onSizeChanged;
  final Color initialColor;
  final String initialEmoji;
  final double initialDensity;
  final double initialSize;

  const EditorSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    this.onColorChanged,
    this.onEmojiChanged,
    this.onDensityChanged,
    this.onSizeChanged,
    required this.initialColor,
    required this.initialEmoji,
    required this.initialDensity,
    required this.initialSize,
  });

  @override
  State<EditorSelector> createState() => _EditorSelectorState();
}

class _EditorSelectorState extends State<EditorSelector> 
    with TickerProviderStateMixin {
  
  Widget _buildSelectorContent() {
    switch (widget.selectedMode) {
      case EditorMode.color:
        return ColorSelector(
          onColorChanged: widget.onColorChanged,
          initialColor: widget.initialColor,
        );
      case EditorMode.emojis:
        return EmojiSelector(
          onEmojiChanged: widget.onEmojiChanged,
          initialEmoji: widget.initialEmoji,
        );
      case EditorMode.layout:
        return LayoutSelector(
          onDensityChanged: widget.onDensityChanged,
          onSizeChanged: widget.onSizeChanged,
          initialDensity: widget.initialDensity,
          initialSize: widget.initialSize,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _buildSelectorContent(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  left: widget.selectedMode.index * (MediaQuery.of(context).size.width - 32) / 3 + 16,
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 32) / 3 - 32,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem('Color', EditorMode.color),
                    _buildBottomNavItem('Emojis', EditorMode.emojis),
                    _buildBottomNavItem('Layout', EditorMode.layout),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(String label, EditorMode mode) {
    final isSelected = widget.selectedMode == mode;
    return GestureDetector(
      onTap: () => widget.onModeChanged(mode),
      child: Container(
        width: (MediaQuery.of(context).size.width - 32) / 3,
        height: 40,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// 颜色选择器
class ColorSelector extends StatefulWidget {
  final ValueChanged<Color>? onColorChanged;
  final Color initialColor;

  const ColorSelector({
    super.key,
    this.onColorChanged,
    required this.initialColor,
  });

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  ColorSwatch? _tempMainColor;
  Color? _tempShadeColor;
  ColorSwatch? _mainColor;
  Color? _shadeColor;

  @override
  void initState() {
    super.initState();
    _shadeColor = widget.initialColor;
    _mainColor = Colors.primaries.firstWhere(
      (color) => color.value == widget.initialColor.value,
      orElse: () => Colors.blue,
    );
  }

  void _openDialog(String title, Widget content) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(18.0),
          title: Text(title),
          content: content,
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _mainColor = _tempMainColor;
                  _shadeColor = _tempShadeColor;
                });
                widget.onColorChanged?.call(_tempShadeColor!);
              },
              child: const Text('SUBMIT'),
            ),
          ],
        );
      },
    );
  }

  void _openColorPicker() async {
    _openDialog(
      "Color picker",
      MaterialColorPicker(
        selectedColor: _shadeColor,
        onColorChange: (color) => setState(() => _tempShadeColor = color),
        onMainColorChange: (color) => setState(() => _tempMainColor = color),
        onBack: () => print("Back button pressed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _shadeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _openColorPicker,
                icon: const Icon(Icons.palette),
                label: const Text('Show color picker'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(200, 40),
                  maximumSize: const Size(200, 40),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Emoji 选择器
class EmojiSelector extends StatefulWidget {
  final ValueChanged<String>? onEmojiChanged;
  final String initialEmoji;

  const EmojiSelector({
    super.key,
    this.onEmojiChanged,
    required this.initialEmoji,
  });

  @override
  State<EmojiSelector> createState() => _EmojiSelectorState();
}

class _EmojiSelectorState extends State<EmojiSelector> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmoji);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24.0),
      padding: const EdgeInsets.all(16.0),
      height: 100,
      child: TextField(
        controller: _controller,
        onChanged: widget.onEmojiChanged,
        decoration: InputDecoration(
          labelText: 'Emojis',
          hintText: '🎄🎆🚀',
          helperText: 'Enter any number of emoji or text.',
          helperStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
          border: const OutlineInputBorder(),
          filled: false,
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _controller.clear();
              widget.onEmojiChanged?.call('');
            },
          ),
        ),
      ),
    );
  }
}

// 布局选择器
class LayoutSelector extends StatefulWidget {
  final ValueChanged<double>? onDensityChanged;
  final ValueChanged<double>? onSizeChanged;
  final double initialDensity;
  final double initialSize;

  const LayoutSelector({
    super.key,
    this.onDensityChanged,
    this.onSizeChanged,
    required this.initialDensity,
    required this.initialSize,
  });

  @override
  State<LayoutSelector> createState() => _LayoutSelectorState();
}

class _LayoutSelectorState extends State<LayoutSelector> {
  late double _densityValue;
  late double _sizeValue;

  @override
  void initState() {
    super.initState();
    _densityValue = widget.initialDensity;
    _sizeValue = widget.initialSize;
  }

    @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Density Row
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Density',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    trackShape: const RoundedRectSliderTrackShape(),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.white,
                  ),
                  child: Slider(
                    value: _densityValue,
                    min: 0,
                    max: 4,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() {
                        _densityValue = value;
                      });
                      widget.onDensityChanged?.call(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Size Row
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Size',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4.0,
                    trackShape: const RoundedRectSliderTrackShape(),
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Colors.white,
                  ),
                  child: Slider(
                    value: _sizeValue,
                    min: 0,
                    max: 4,
                    divisions: 4,
                    onChanged: (value) {
                      setState(() {
                        _sizeValue = value;
                      });
                      widget.onSizeChanged?.call(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 