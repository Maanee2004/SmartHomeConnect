import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/screens/auth/register_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_auth_repository.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/app_brand_header.dart';
import 'package:smart_home/widgets/custom_text_field.dart';
import 'package:smart_home/widgets/glow_button.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _focusEmail = FocusNode();
  final _focusPhone = FocusNode();
  final _focusPassword = FocusNode();

  bool _useEmail = true;
  bool _obscure = true;
  bool _rememberMe = false;
  bool _submitting = false;
  String _selectedCountry = 'Mali';

  bool _isEmailValid = true;
  bool _isPhoneValid = true;

  static const String _rememberPhoneKey = 'remember_phone';
  static const String _savedPhoneKey = 'saved_phone';
  static const String _rememberEmailKey = 'remember_email';
  static const String _savedEmailKey = 'saved_email';
  static const String _loginUseEmailKey = 'login_use_email';

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
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberPhone = prefs.getBool(_rememberPhoneKey) ?? false;
    final savedPhone = prefs.getString(_savedPhoneKey) ?? '';
    final rememberEmail = prefs.getBool(_rememberEmailKey) ?? false;
    final savedEmail = prefs.getString(_savedEmailKey) ?? '';
    final savedModeEmail = prefs.getBool(_loginUseEmailKey);

    if (!mounted) return;

    setState(() {
      if (rememberPhone && savedPhone.isNotEmpty) {
        _useEmail = false;
        _rememberMe = true;
        _phoneController.text = savedPhone;
      } else if (rememberEmail && savedEmail.isNotEmpty) {
        _useEmail = true;
        _rememberMe = true;
        _emailController.text = savedEmail;
      } else if (savedModeEmail != null) {
        _useEmail = savedModeEmail;
        _rememberMe = rememberPhone || rememberEmail;
      }
    });
  }

  Future<void> _saveCredentialsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginUseEmailKey, _useEmail);

    if (!_rememberMe) {
      await prefs.remove(_rememberPhoneKey);
      await prefs.remove(_savedPhoneKey);
      await prefs.remove(_rememberEmailKey);
      await prefs.remove(_savedEmailKey);
      return;
    }

    if (_useEmail) {
      await prefs.setBool(_rememberEmailKey, true);
      await prefs.setString(_savedEmailKey, _emailController.text.trim());
      await prefs.remove(_rememberPhoneKey);
      await prefs.remove(_savedPhoneKey);
    } else {
      await prefs.setBool(_rememberPhoneKey, true);
      await prefs.setString(_savedPhoneKey, _phoneController.text.trim());
      await prefs.remove(_rememberEmailKey);
      await prefs.remove(_savedEmailKey);
    }
  }

  @override
  void dispose() {
    _focusEmail.dispose();
    _focusPhone.dispose();
    _focusPassword.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      _isEmailValid = _validateEmail(_emailController.text);
      _isPhoneValid = _validatePhone(_phoneController.text);
    });
  }

  void _showForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: const Text(
          'La réinitialisation du mot de passe sera disponible bientôt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (_useEmail) {
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
    } else {
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
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe est requis')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = await FirestoreAuthRepository.instance.login(
        email: _useEmail ? email : null,
        phone: _useEmail ? null : _fullPhone,
        plainPassword: password,
      );
      await _saveCredentialsPreference();
      await AuthService.instance.saveSession(user);
      await FirestoreHomeRepository.bootstrap();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _modeToggle() {
    final c = context.smartColors;
    final inactiveBorder = c.textSecondary.withValues(alpha: 0.45);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                _useEmail = true;
                _validateFields();
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _useEmail
                      ? accentColor.withValues(alpha: 0.25)
                      : c.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _useEmail ? accentColor : inactiveBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Email',
                  style: TextStyle(
                    color: _useEmail ? accentColor : c.textSecondary,
                    fontWeight: _useEmail ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                _useEmail = false;
                _validateFields();
              }),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_useEmail
                      ? accentColor.withValues(alpha: 0.25)
                      : c.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !_useEmail ? accentColor : inactiveBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Téléphone',
                  style: TextStyle(
                    color: !_useEmail ? accentColor : c.textSecondary,
                    fontWeight:
                        !_useEmail ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                const Center(child: AppBrandHeader()),
                const Positioned(
                  top: 0,
                  right: 8,
                  child: ThemeToggleButton(),
                ),
              ],
            ),
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
                      'Bienvenue',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Connecte-toi pour continuer',
                      style: TextStyle(color: c.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    _modeToggle(),
                    const SizedBox(height: 12),
                    if (_useEmail)
                      CustomTextField(
                        hint: 'Email',
                        icon: Icons.email,
                        controller: _emailController,
                        focusNode: _focusEmail,
                        semanticsLabel: 'Adresse e-mail',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _focusPassword.requestFocus(),
                        onChanged: (_) => _validateFields(),
                      )
                    else
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
                                      style: const TextStyle(fontSize: 12),
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
                              hint:
                                  '${_phoneLengths[_selectedCountry] ?? 8} chiffres',
                              icon: Icons.phone,
                              controller: _phoneController,
                              focusNode: _focusPhone,
                              semanticsLabel: 'Numéro de téléphone',
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _focusPassword.requestFocus(),
                              onChanged: (_) => _validateFields(),
                            ),
                          ),
                        ],
                      ),
                    if (_useEmail && !_isEmailValid) ...[
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email invalide',
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    ],
                    if (!_useEmail &&
                        !_isPhoneValid &&
                        _phoneController.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Numéro invalide pour le pays choisi',
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    CustomTextField(
                      hint: 'Mot de passe',
                      icon: Icons.lock,
                      obscure: _obscure,
                      controller: _passwordController,
                      focusNode: _focusPassword,
                      semanticsLabel: 'Mot de passe',
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            _submitting ? null : _showForgotPasswordDialog,
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: accentColor.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Text(
                              'Se souvenir de moi',
                              style: TextStyle(color: c.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GlowButton(
                      text: 'Se connecter',
                      loading: _submitting,
                      enabled: !_submitting,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas de compte ? ',
                          style: TextStyle(color: c.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'S’inscrire',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
