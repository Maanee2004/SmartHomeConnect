import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/house_invites_repository.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/custom_text_field.dart';
import 'package:smart_home/widgets/glow_button.dart';

/// Rejoindre une maison avec un code invité à 5 chiffres.
class JoinHouseScreen extends StatefulWidget {
  const JoinHouseScreen({super.key});

  @override
  State<JoinHouseScreen> createState() => _JoinHouseScreenState();
}

class _JoinHouseScreenState extends State<JoinHouseScreen> {
  final _codeController = TextEditingController();
  final _focusCode = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _focusCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    setState(() => _submitting = true);
    try {
      final user = await HouseInvitesRepository.instance.joinHouseWithCode(
        memberUserId: userId,
        code: _codeController.text.trim(),
      );
      await AuthService.instance.saveSession(user);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maison rejointe avec succès.')),
      );
      Navigator.of(context).pop(true);
    } on InviteFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onCodeChanged(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits != v) {
      _codeController.value = TextEditingValue(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final codeLen = _codeController.text.trim().length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Rejoindre une maison',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: AdaptiveContent(
        padding: context.responsive.listPadding,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Icon(Icons.home_work_outlined, size: 56, color: accentColor),
            const SizedBox(height: 16),
            Text(
              'Code d’invitation',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Demandez le code à 5 chiffres au propriétaire de la maison. '
              'En tant que membre, vous pourrez piloter les appareils sans modifier la configuration.',
              style: TextStyle(color: c.textSecondary, height: 1.45),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            CustomTextField(
              hint: 'Ex. 48291',
              icon: Icons.pin_outlined,
              controller: _codeController,
              focusNode: _focusCode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (codeLen == 5) _submit();
              },
              onChanged: _onCodeChanged,
            ),
            const SizedBox(height: 24),
            GlowButton(
              text: 'Rejoindre',
              loading: _submitting,
              enabled: codeLen == 5,
              onTap: _submit,
            ),
            const SizedBox(height: 16),
            Material(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: accentColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous êtes connecté en tant que '
                        '${AuthService.instance.currentUserId ?? '—'}. '
                        'Seuls les comptes utilisateur standard peuvent rejoindre une maison.',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
