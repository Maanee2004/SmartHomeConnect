import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/exceptions/home_data_exception.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/home_repository.dart';

/// Dialogue de choix / saisie d’une broche GPIO (2–53).
Future<int?> showPinPickerDialog(
  BuildContext context, {
  required HomeRepository repo,
  required bool required,
  int? currentPin,
  String? title,
  String? subtitle,
}) async {
  List<int> freePins = [];
  try {
    freePins = await repo.availablePins();
  } catch (_) {
    freePins = [];
  }
  if (currentPin != null && !freePins.contains(currentPin)) {
    freePins = [currentPin, ...freePins]..sort();
  }

  if (!context.mounted) return null;

  return showDialog<int>(
    context: context,
    builder: (ctx) => _PinPickerDialog(
      freePins: freePins,
      required: required,
      currentPin: currentPin,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _PinPickerDialog extends StatefulWidget {
  const _PinPickerDialog({
    required this.freePins,
    required this.required,
    this.currentPin,
    this.title,
    this.subtitle,
  });

  final List<int> freePins;
  final bool required;
  final int? currentPin;
  final String? title;
  final String? subtitle;

  @override
  State<_PinPickerDialog> createState() => _PinPickerDialogState();
}

class _PinPickerDialogState extends State<_PinPickerDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.currentPin != null) {
      _ctrl.text = '${widget.currentPin}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int? _parsePin() {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    if (n == null) {
      setState(() => _error = 'Saisis un numéro valide.');
      return null;
    }
    try {
      AppareilSpec.validatePin(n);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message?.toString() ?? '$e');
      return null;
    }
    setState(() => _error = null);
    return n;
  }

  void _submit() {
    final pin = _parsePin();
    if (pin == null) {
      if (widget.required) return;
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) {
    final range =
        'Broches ${AppareilSpec.minPin}–${AppareilSpec.maxPin} (Arduino / ESP32)';

    return AlertDialog(
      title: Text(
        widget.title ??
            (widget.required ? 'Choisir une broche' : 'Broche (optionnel)'),
        style: TextStyle(color: context.smartColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.subtitle!,
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 13),
                ),
              ),
            Text(
              range,
              style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: context.smartColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Numéro de broche',
                labelStyle: TextStyle(color: context.smartColors.textSecondary),
                hintText: 'ex. ${widget.freePins.isNotEmpty ? widget.freePins.first : 2}',
                hintStyle: TextStyle(color: context.smartColors.textSecondary),
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (widget.freePins.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Broches libres',
                style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.freePins.take(24).map((p) {
                  final selected = _ctrl.text.trim() == '$p';
                  return ActionChip(
                    label: Text('$p'),
                    backgroundColor: selected
                        ? accentColor.withValues(alpha: 0.25)
                        : inputFillColor,
                    labelStyle: TextStyle(
                      color: selected ? accentColor : textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    onPressed: () {
                      _ctrl.text = '$p';
                      setState(() => _error = null);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.required)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Passer'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text('Valider'),
        ),
      ],
    );
  }
}

/// Affiche les erreurs pin de façon lisible.
String describePinError(Object error) {
  if (error is PinAlreadyAssignedException ||
      error is AppareilValidationException) {
    return error.toString();
  }
  return FirestoreHomeRepository.describeFirebaseError(error);
}
