import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Split-screen sign-in and registration screen backed by the PHP REST API.
/// New registrations are assigned the regular "user" role by the server.
class AuthDialog extends StatefulWidget {
  const AuthDialog({
    super.key,
    required this.api,
    this.startWithSignUp = false,
    this.fullScreen = false,
    this.onAuthenticated,
  });

  final ApiService api;
  final bool startWithSignUp;
  final bool fullScreen;
  final Future<void> Function(Map<String, dynamic> result)? onAuthenticated;

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  static const Color _teal = Color(0xFF347F7D);
  static const Color _ink = Color(0xFF172322);
  static const String _heroImageUrl =
      'https://images.pexels.com/photos/16812195/pexels-photo-16812195.jpeg?cs=srgb&dl=pexels-ferdie-cayanga-297619-16812195.jpg&fm=jpg';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late bool _isSignUp = widget.startWithSignUp;
  bool _isBusy = false;
  bool _hidePassword = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _changeMode(bool signUp) {
    if (_isBusy || signUp == _isSignUp) return;
    setState(() {
      _isSignUp = signUp;
      _errorMessage = null;
      _acceptedTerms = false;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp && !_acceptedTerms) {
      setState(() => _errorMessage =
          'Please agree to the Terms and Conditions and Privacy Policy.');
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      if (_isSignUp) {
        await widget.api.register(
          _nameController.text.trim(),
          email,
          password,
        );
      }
      final result = await widget.api.login(email, password);
      if (!mounted) return;
      final onAuthenticated = widget.onAuthenticated;
      if (onAuthenticated != null) {
        await onAuthenticated(result);
      } else {
        Navigator.of(context).pop(result);
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final availableWidth = widget.fullScreen
        ? screen.width
        : math.min(screen.width - 24, 1120.0)
            .clamp(260.0, 1120.0)
            .toDouble();
    final availableHeight = widget.fullScreen
        ? screen.height
        : math.min(screen.height - 24, 760.0)
            .clamp(300.0, 760.0)
            .toDouble();
    final isWide = availableWidth >= 740;

    final content = SizedBox(
      width: availableWidth,
      height: availableHeight,
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 10, child: _buildHeroPanel(compact: false)),
                Expanded(flex: 11, child: _buildFormPanel(compact: false)),
              ],
            )
          : Column(
              children: [
                SizedBox(height: math.min(190.0, availableHeight * 0.25).toDouble(), child: _buildHeroPanel(compact: true)),
                Expanded(child: _buildFormPanel(compact: true)),
              ],
            ),
    );

    if (widget.fullScreen) {
      return Material(
        color: Colors.white,
        child: content,
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: content,
    );
  }

  Widget _buildHeroPanel({required bool compact}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          _heroImageUrl,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A7775), Color(0xFF073F45)],
              ),
            ),
            child: const Center(
              child: Icon(Icons.travel_explore, color: Colors.white54, size: 76),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF062F32).withValues(alpha: 0.40),
                const Color(0xFF063C3D).withValues(alpha: 0.30),
                const Color(0xFF062B30).withValues(alpha: 0.82),
              ],
              stops: const [0, 0.46, 1],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(compact ? 18 : 34),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandMark(compact: true),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isSignUp
                                ? 'Find your next adventure.'
                                : 'Welcome back, traveler.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _HeroModeButton(
                          label: _isSignUp ? 'Login' : 'Sign up',
                          onPressed: () => _changeMode(!_isSignUp),
                          compact: true,
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandMark(),
                    const Spacer(),
                    Text(
                      'TRAVEL AND DISCOVER',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 10,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      _isSignUp
                          ? 'Find your next\nadventure.'
                          : 'Your next Bohol\nadventure awaits.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        height: 1.13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 13),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Text(
                        'Explore beautiful places, discover local experiences, and make every trip to Bohol memorable.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    _HeroModeButton(
                      label: _isSignUp ? 'Login' : 'Create account',
                      onPressed: () => _changeMode(!_isSignUp),
                    ),
                    const Spacer(),
                    Text(
                      'BOHOL, PHILIPPINES  •  YOUR LOCAL TRAVEL GUIDE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFormPanel({required bool compact}) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                compact ? 24 : 48,
                compact ? 50 : 62,
                compact ? 24 : 48,
                compact ? 22 : 34,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 390),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isSignUp ? 'Create account' : 'Welcome back',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _buildModeDescription(),
                      const SizedBox(height: 30),
                      if (_isSignUp) ...[
                        _buildInput(
                          controller: _nameController,
                          hint: 'Your name',
                          textCapitalization: TextCapitalization.words,
                          validator: (value) =>
                              (value == null || value.trim().length < 2)
                                  ? 'Enter your full name.'
                                  : null,
                        ),
                        const SizedBox(height: 17),
                      ],
                      _buildInput(
                        controller: _emailController,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(email)
                              ? null
                              : 'Enter a valid email address.';
                        },
                      ),
                      const SizedBox(height: 17),
                      _buildInput(
                        controller: _passwordController,
                        hint: 'Password',
                        obscureText: _hidePassword,
                        suffix: IconButton(
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                          tooltip: _hidePassword ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 19,
                            color: const Color(0xFF81918F),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          if (_isSignUp && value.length < 8) {
                            return 'Use at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                      if (_isSignUp) ...[
                        const SizedBox(height: 17),
                        _buildInput(
                          controller: _confirmController,
                          hint: 'Confirm password',
                          obscureText: _hidePassword,
                          validator: (value) =>
                              value != _passwordController.text
                                  ? 'Passwords do not match.'
                                  : null,
                        ),
                        const SizedBox(height: 13),
                        _buildTermsRow(),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 13),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF5D2D2)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFF9C2929),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 21),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _isBusy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _teal.withValues(alpha: 0.55),
                            shape: const StadiumBorder(),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          child: _isBusy
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isSignUp ? 'Create account' : 'Sign in'),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Color(0xFFE9EEEE))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'BOHOL EXPLORER',
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 9,
                                letterSpacing: 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Color(0xFFE9EEEE))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? 'Already have an account? '
                                  : "Don't have an account? ",
                              style: const TextStyle(
                                color: Color(0xFF75827F),
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: _isBusy
                                  ? null
                                  : () => _changeMode(!_isSignUp),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: _teal,
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: Text(_isSignUp ? 'Sign in' : 'Create account'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'By continuing, you agree to use Bohol Explorer responsibly and respect local communities and destinations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.shade300,
                          fontSize: 9,
                          height: 1.45,
                        ),
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

  Widget _buildModeDescription() {
    return Text(
      _isSignUp
          ? 'Create your account to save destinations and plan your next trip.'
          : 'Sign in to continue exploring Bohol and your saved travel guides.',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color(0xFF71807E),
        fontSize: 11,
        height: 1.5,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: _ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF8D9997), fontSize: 12),
        suffixIcon: suffix,
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF9AA8A5), width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _teal, width: 1.7),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC45B5B)),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC45B5B), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 25,
          height: 25,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: _isBusy
                ? null
                : (value) => setState(() {
                      _acceptedTerms = value ?? false;
                      if (_acceptedTerms &&
                          _errorMessage?.startsWith('Please agree') == true) {
                        _errorMessage = null;
                      }
                    }),
            activeColor: _teal,
            side: const BorderSide(color: Color(0xFFBAC7C4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              'I agree to the Terms and Conditions and Privacy Policy.',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 29 : 34,
          height: compact ? 29 : 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.travel_explore_rounded,
            size: compact ? 17 : 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'BOHOL EXPLORER',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.65,
          ),
        ),
      ],
    );
  }
}

class _HeroModeButton extends StatelessWidget {
  const _HeroModeButton({
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.9), width: 1),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 15 : 25,
          vertical: compact ? 8 : 12,
        ),
        minimumSize: Size(compact ? 0 : 104, compact ? 32 : 40),
        shape: const StadiumBorder(),
        textStyle: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}
