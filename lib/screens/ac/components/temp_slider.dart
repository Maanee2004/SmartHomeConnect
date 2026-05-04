import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../widget_utils.dart';

class TemperatureSlider extends StatelessWidget {
  final ValueChanged<double> onTempChanged;
  final double maxTemp;
  final double minTemp;
  final double currentTemp;
  final Color tempColor;

  const TemperatureSlider({
    super.key,
    required this.onTempChanged,
    required this.maxTemp,
    required this.minTemp,
    required this.currentTemp,
    required this.tempColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.all(defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: wrapInCard(
              backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.82),
              padding: defaultPadding - 4,
              widget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Temp', style: Theme.of(context).textTheme.bodyLarge),
                  Row(
                    children: [
                      Text('${minTemp.toInt()}°C'),
                      Expanded(
                        child: Slider(
                          activeColor: tempColor,
                          inactiveColor: scheme.onSurface.withValues(alpha: 0.12),
                          value: currentTemp,
                          max: maxTemp,
                          min: minTemp,
                          onChanged: onTempChanged,
                        ),
                      ),
                      Text('${maxTemp.toInt()}°C'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
