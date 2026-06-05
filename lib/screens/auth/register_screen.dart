import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_auth_repository.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/app_brand_header.dart';
import 'package:smart_home/widgets/custom_text_field.dart';
import 'package:smart_home/widgets/glow_button.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String _selectedCountry = 'Mali';

  bool _isFirstNameValid = true;
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isPhoneValid = true;

  final Map<String, String> _countryCodes = {
    'Mali': '+223',
    'France': '+33',
    'Sénégal': '+221',
    'Côte d\'Ivoire': '+225',
    'Burkina Faso': '+226',
    'Niger': '+227',
    'Guinée': '+224',
  };

  final Map<String, int> _phoneLengths = {
    'Mali': 8,
    'France': 9,
    'Sénégal': 9,
    'Côte d\'Ivoire': 10,
    'Burkina Faso': 8,
    'Niger': 8,
    'Guinée': 9,
  };

  String get _fullPhone =>
      '${_countryCodes[_selectedCountry]}${_phoneController.text.trim()}';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validateFirstName(String name) {
    if (name.isEmpty) return false;
    if (name.length < 2) return false;
    return RegExp(r'^[a-zA-Z\s-]+$').hasMatch(name);
  }

  bool _validateLastName(String name) {
    if (name.isEmpty) return false;
    if (name.length < 2) return false;
    return RegExp(r'^[a-zA-Z\s-]+$').hasMatch(name);
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _validatePhone(String phone) {
    if (phone.isEmpty) return false;
    final requiredLength = _phoneLengths[_selectedCountry] ?? 8;
    if (phone.length != requiredLength) return false;
    return RegExp(r'^[0-9]+$').hasMatch(phone);
  }

  void _validateFields() {
    setState(() {
      _isFirstNameValid = _validateFirstName(_firstNameController.text);
      _isLastNameValid = _validateLastName(_lastNameController.text);
      _isEmailValid = _validateEmail(_emailController.text);
      _isPhoneValid = _validatePhone(_phoneController.text);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom est requis')),
      );
      return;
    }
    if (lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom est requis')),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L’email est requis')),
      );
      return;
    }
    if (!_validateEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email invalide')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le numéro de téléphone est requis')),
      );
      return;
    }
    if (!_validatePhone(phone)) {
      final requiredLength = _phoneLengths[_selectedCountry] ?? 8;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Numéro invalide: $_selectedCountry nécessite $requiredLength chiffres',
          ),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe est requis')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mot de passe trop court (6 caractères min.)')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    _validateFields();
    if (!_isFirstNameValid || !_isLastNameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prénom ou nom invalide')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final displayName =
          [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
      final user = await FirestoreAuthRepository.instance.register(
        name: displayName,
        email: email,
        phone: _fullPhone,
        plainPassword: password,
      );
      await AuthService.instance.saveSession(user);
      await FirestoreHomeRepository.bootstrap();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ton compte a été créé avec succès')),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d’inscription : $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(
          'Inscription',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Column(
        children: [
          const SafeArea(
            bottom: false,
            child: AppBrandHeader(compact: true, showTagline: false),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Email et téléphone obligatoires',
                  style: TextStyle(color: c.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hint: 'Prénom',
                        icon: Icons.person_outline,
                        controller: _firstNameController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _validateFields(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        hint: 'Nom',
                        icon: Icons.person,
                        controller: _lastNameController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _validateFields(),
                      ),
                    ),
                  ],
                ),
                if (!_isFirstNameValid || !_isLastNameValid) ...[
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Prénom / nom invalides (lettres, 2 caractères min.)',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                CustomTextField(
                  hint: 'Email',
                  icon: Icons.email,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _validateFields(),
                ),
                if (!_isEmailValid && _emailController.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email invalide',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: c.inputFill,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: accentColor, width: 1),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCountry,
                          dropdownColor: c.card,
                          iconEnabledColor: c.textSecondary,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 13,
                          ),
                          isDense: true,
                          items: _countryCodes.keys.map((country) {
                            return DropdownMenuItem(
                              value: country,
                              child: Text(
                                '${_countryCodes[country]} $country',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedCountry = v;
                                _validateFields();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomTextField(
                        hint: '${_phoneLengths[_selectedCountry] ?? 8} chiffres',
                        icon: Icons.phone,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => _validateFields(),
                      ),
                    ),
                  ],
                ),
                if (!_isPhoneValid && _phoneController.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Numéro invalide pour le pays choisi',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                CustomTextField(
                  hint: 'Mot de passe',
                  icon: Icons.lock,
                  obscure: _obscurePassword,
                  controller: _passwordController,
                  textInputAction: TextInputAction.next,
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomTextField(
                  hint: 'Confirmer mot de passe',
                  icon: Icons.lock_outline,
                  obscure: _obscureConfirm,
                  controller: _confirmController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GlowButton(
                  text: 'S\'inscrire',
                  loading: _submitting,
                  enabled: !_submitting,
                  onTap: _submit,
                ),
                const SizedBox(height: 15),
                Text(
                  'Déjà un compte ? Reviens à la connexion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }
}
