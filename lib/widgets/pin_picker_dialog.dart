import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/services/auth_service.dart';
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
  String? deviceType,
}) async {
  List<int> freePins = [];
  Map<int, String> usedPins = {};
  try {
    freePins = await repo.availablePins();
    usedPins = await repo.pinUsageLabels();
  } catch (_) {
    freePins = [];
    usedPins = {};
  }
  if (currentPin != null && !freePins.contains(currentPin)) {
    freePins = [currentPin, ...freePins]..sort();
  }

  if (!context.mounted) return null;

  final showTechnical = AuthService.instance.isAdmin;

  return showDialog<int>(
    context: context,
    builder: (ctx) => _PinPickerDialog(
      freePins: freePins,
      usedPins: usedPins,
      required: required,
      currentPin: currentPin,
      title: title,
      subtitle: subtitle,
      deviceType: deviceType,
      showTechnicalDetails: showTechnical,
    ),
  );
}

class _PinPickerDialog extends StatefulWidget {
  const _PinPickerDialog({
    required this.freePins,
    required this.usedPins,
    required this.required,
    this.currentPin,
    this.title,
    this.subtitle,
    this.deviceType,
    required this.showTechnicalDetails,
  });

  final List<int> freePins;
  final Map<int, String> usedPins;
  final bool required;
  final int? currentPin;
  final String? title;
  final String? subtitle;
  final String? deviceType;
  final bool showTechnicalDetails;

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
    final l = context.l10n;
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return null;
    final n = int.tryParse(raw);
    if (n == null) {
      setState(() => _error = l.pinEnterValidNumber);
      return null;
    }
    if (AppareilSpec.reservedPins.contains(n)) {
      setState(() => _error = l.pinReservedNotAllowed(n));
      return null;
    }
    try {
      AppareilSpec.validatePin(n);
      if (widget.deviceType != null) {
        AppareilSpec.validatePinForDeviceType(n, widget.deviceType!);
      }
    } on ArgumentError catch (e) {
      setState(() => _error = e.message?.toString() ?? '$e');
      return null;
    }

    final occupant = widget.usedPins[n];
    final isCurrent = widget.currentPin == n;
    if (occupant != null && !isCurrent) {
      setState(() => _error = l.pinOccupiedBy(n, occupant));
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
    final l = context.l10n;
    final range = widget.showTechnicalDetails
        ? l.pinRangeTechnical(AppareilSpec.minPin, AppareilSpec.maxPin)
        : l.pinRangeUser(AppareilSpec.minPin, AppareilSpec.maxPin);

    final usedEntries = widget.usedPins.entries
        .where((e) => !AppareilSpec.reservedPins.contains(e.key))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final reservedSorted = AppareilSpec.reservedPins.toList()..sort();

    return AlertDialog(
      title: Text(
        widget.title ??
            (widget.required ? l.pinChooseTitle : l.pinOptionalTitle),
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
                  style: TextStyle(
                    color: context.smartColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            Text(
              range,
              style: TextStyle(
                color: context.smartColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.pinReservedSectionTitle,
              style: TextStyle(
                color: context.smartColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reservedSorted.map((p) {
                final role = widget.showTechnicalDetails
                    ? AppareilSpec.reservedPinRoles[p]
                    : null;
                final suffix = role != null ? ' — $role' : ' — ESP32';
                return FilterChip(
                  label: Text(l.pinReservedLine(p, suffix)),
                  avatar: Icon(
                    Icons.block,
                    size: 16,
                    color: warningColor.withValues(alpha: 0.95),
                  ),
                  selected: true,
                  onSelected: null,
                  showCheckmark: false,
                  backgroundColor: warningColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: context.smartColors.textSecondary,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
            if (widget.showTechnicalDetails) ...[
              const SizedBox(height: 6),
              Text(
                l.pinReservedHint(AppareilSpec.reservedPinsListText),
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: context.smartColors.textPrimary),
              decoration: InputDecoration(
                labelText: l.pinNumberLabel,
                labelStyle: TextStyle(color: context.smartColors.textSecondary),
                hintText: l.pinHintExample(
                  widget.freePins.isNotEmpty ? widget.freePins.first : 2,
                ),
                hintStyle: TextStyle(color: context.smartColors.textSecondary),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            if (widget.freePins.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l.pinFreeLabel,
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 12,
                ),
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
            if (usedEntries.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l.pinOccupiedLabel,
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ...usedEntries.take(12).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: warningColor.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l.pinOccupiedBy(e.key, e.value),
                              style: TextStyle(
                                color: context.smartColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (usedEntries.length > 12)
                Text(
                  l.pinOccupiedMore(usedEntries.length - 12),
                  style: TextStyle(
                    color: context.smartColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        if (!widget.required)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.pinSkip),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l.pinValidate),
        ),
      ],
    );
  }
}

/// Affiche les erreurs pin de façon lisible.
String describePinError(Object error) {
  if (error is PinAlreadyAssignedException) {
    return error.messageForUser(
      includeTechnicalIds: AuthService.instance.isAdmin,
    );
  }
  if (error is AppareilValidationException) {
    return error.toString();
  }
  return FirestoreHomeRepository.describeFirebaseError(error);
}
