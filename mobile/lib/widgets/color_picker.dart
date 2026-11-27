import 'package:flutter/material.dart';

import '../models/lighting_settings.dart';
import '../theme.dart';

class LightingColorPicker extends StatelessWidget {
  const LightingColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Color selected;
  final ValueChanged<LightingSwatch> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: LightingSwatch.palette.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final swatch = LightingSwatch.palette[index];
          final isSelected = swatch.color == selected;
          return GestureDetector(
            onTap: () => onSelected(swatch),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: swatch.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? StudioTheme.cream : Colors.white24,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  swatch.name,
                  style: TextStyle(
                    color: isSelected ? StudioTheme.cream : StudioTheme.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
