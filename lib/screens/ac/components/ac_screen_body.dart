import 'package:flutter/material.dart';
import 'package:smart_home/screens/ac/components/clouds_video_player.dart';

import '../../../constants.dart';
import 'conditioner_mode.dart';
import 'panel_control.dart';
import 'power_control.dart';
import 'speed_control.dart';
import 'temp_display.dart';
import 'temp_slider.dart';

class ACScreenBody extends StatefulWidget {
  const ACScreenBody({
    super.key,
  });

  @override
  _ACScreenBodyState createState() => _ACScreenBodyState();
}

class _ACScreenBodyState extends State<ACScreenBody> {
  double _currentTemp = 23;
  bool _powerdOn = false;
  bool _gridAvailable = true;
  bool _panelOn = false;
  int _currentSpeed = 1;
  int _currentItem = 1;

  final double _maxTemp = 30;
  final double _minTemp = 16;

  double _progress = 0.5;
  Color _temperatureTint = getColor(0.5);

  double _getProgress(double value) =>
      ((value - _minTemp) / (_maxTemp - _minTemp));

  void _updateSelectedItem(int item) => setState(() {
        _currentItem = item;
      });

  void _updateFanSpeed(int speed) => setState(() {
        _currentSpeed = speed;
      });

  void _updatePowerState(bool isChecked) {
    final canPower = _gridAvailable || _panelOn;
    if (isChecked && !canPower) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Coupure d’électricité: active le panneau (secours) pour allumer l’AC.",
          ),
        ),
      );
      return;
    }
    setState(() {
      _powerdOn = isChecked;
    });
  }

  void _updateGridAvailability(bool available) => setState(() {
        _gridAvailable = available;
        if (!_gridAvailable && !_panelOn) {
          _powerdOn = false;
        }
      });

  void _updatePanelState(bool isOn) => setState(() {
        _panelOn = isOn;
        if (!_gridAvailable && !_panelOn) {
          _powerdOn = false;
        }
      });

  void _updateTemperature(double temp) => setState(() {
        _currentTemp = temp;
        _progress = _getProgress(_currentTemp);
        _temperatureTint = getColor(_progress);
      });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPower = _gridAvailable || _panelOn;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _temperatureTint.withValues(alpha: 0.1),
            _temperatureTint,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CloudsVideo(speed: _currentSpeed),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'Réseau',
                        value: _gridAvailable ? 'ON' : 'OFF',
                        color: _gridAvailable
                            ? primaryColor.withValues(alpha: 0.9)
                            : accentColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(
                        label: 'Panneau',
                        value: _panelOn ? 'ON' : 'OFF',
                        color: _panelOn
                            ? primaryColor.withValues(alpha: 0.9)
                            : scheme.onSurface.withValues(alpha: 0.35),
                      ),
                      const Spacer(),
                      _QuickToggle(
                        label: 'Coupure',
                        isOn: !_gridAvailable,
                        onChanged: (v) => _updateGridAvailability(!v),
                      ),
                    ],
                  ),
                ),
                if (!canPower)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: defaultPadding,
                      vertical: 6,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        "Coupure d'électricité: active le panneau (secours) pour allumer l'AC.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ConditionerMode(
                  onTap: _updateSelectedItem,
                  selectedItem: _currentItem,
                  tempColor: _temperatureTint,
                ),
                Expanded(
                  child: TempDisplay(
                    currentTemp: _currentTemp,
                    progress: _progress,
                    mColor: _temperatureTint,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: defaultPadding),
                  child: Container(
                    height: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SpeedControl(
                          currentSpeed: _currentSpeed,
                          onSpeedChanged: _updateFanSpeed,
                          tempColor: _temperatureTint,
                        ),
                        SizedBox(width: defaultPadding),
                        PanelControl(
                          isOn: _panelOn,
                          onSwitched: _updatePanelState,
                          tempColor: _temperatureTint,
                        ),
                        SizedBox(width: defaultPadding),
                        PowerControl(
                          isOn: _powerdOn,
                          onSwitched: _updatePowerState,
                          tempColor: _temperatureTint,
                        ),
                      ],
                    ),
                  ),
                ),
                TemperatureSlider(
                  minTemp: _minTemp,
                  maxTemp: _maxTemp,
                  currentTemp: _currentTemp,
                  onTempChanged: _updateTemperature,
                  tempColor: _temperatureTint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _QuickToggle extends StatelessWidget {
  const _QuickToggle({
    required this.label,
    required this.isOn,
    required this.onChanged,
  });

  final String label;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!isOn),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            Icon(
              isOn ? Icons.flash_off_rounded : Icons.flash_on_rounded,
              size: 18,
              color: isOn
                  ? accentColor.withValues(alpha: 0.9)
                  : primaryColor.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}
