import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../constants.dart';
import '../../../widget_utils.dart';

class PanelControl extends StatelessWidget {
  const PanelControl({
    super.key,
    required this.isOn,
    required this.onSwitched,
    required this.tempColor,
  });

  final bool isOn;
  final ValueChanged<bool> onSwitched;
  final Color tempColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: wrapInCard(
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.82),
        padding: defaultPadding - 4,
        widget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panneau', style: Theme.of(context).textTheme.bodyLarge),
            Text(
              'Secours solaire',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'OFF',
                        style: TextStyle(
                          color: scheme.onSurface
                              .withValues(alpha: isOn ? 0.35 : 1),
                        ),
                      ),
                      TextSpan(
                        text: '/',
                        style:
                            TextStyle(color: scheme.onSurface.withValues(alpha: 0.35)),
                      ),
                      TextSpan(
                        text: 'ON',
                        style: TextStyle(
                          color:
                              scheme.onSurface.withValues(alpha: isOn ? 1 : 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    activeTrackColor: tempColor.withValues(alpha: 0.6),
                    inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
                    value: isOn,
                    onChanged: onSwitched,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

