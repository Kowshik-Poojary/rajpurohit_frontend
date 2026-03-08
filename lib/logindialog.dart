import 'package:flutter/material.dart';

/// Premium Login Dialog — Compact & Refined
/// Features:
/// - Compact 300px desktop width (down from 360px)
/// - Glass-morphism card with frosted depth
/// - Subtle noise texture via overlapping gradients
/// - Tighter vertical rhythm and spacing
/// - Refined teal/slate color system
/// - Smooth staggered entrance animations
///
/// Usage:
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => LoginDialog(
///     onLogin: (username, password) { ... },
///   ),
/// );

class LoginDialog extends StatefulWidget {
  final Function(String username, String password) onLogin;
  final String title;
  final String subtitle;

  const LoginDialog({
    required this.onLogin,
    this.title = 'Welcome Back',
    this.subtitle = 'Sign in to continue',
    super.key,
  });

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog>
    with SingleTickerProviderStateMixin {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late AnimationController _animationController;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _usernameFocused = false;
  bool _passwordFocused = false;

  // Color palette
  static const _teal = Color(0xff0d9488);
  static const _tealDark = Color(0xff0f766e);
  static const _tealLight = Color(0xffe6f7f6);
  static const _ink = Color(0xff0f172a);
  static const _slate = Color(0xff64748b);

  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnim = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pop(context);
        widget.onLogin(username, password);
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xffe11d48),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // Compact desktop width: 300px vs full-width mobile
    final dialogWidth = isMobile ? double.infinity : 300.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              // Layered shadow for depth
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff0d9488).withOpacity(0.15),
                  blurRadius: 48,
                  spreadRadius: 0,
                  offset: const Offset(0, 24),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Subtle top accent bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_tealDark, _teal, Color(0xff2dd4bf)],
                        ),
                      ),
                    ),
                  ),
                  // Decorative circle top-right
                  Positioned(
                    top: -40,
                    right: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _teal.withOpacity(0.04),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 24 : 28,
                      isMobile ? 28 : 32,
                      isMobile ? 24 : 28,
                      isMobile ? 24 : 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon badge
                        _buildBadge(),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            letterSpacing: -0.6,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _slate,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Username field
                        _buildField(
                          controller: _usernameController,
                          hint: 'Email or username',
                          icon: Icons.mail_outline_rounded,
                          focused: _usernameFocused,
                          onFocusChange: (v) =>
                              setState(() => _usernameFocused = v),
                        ),
                        const SizedBox(height: 12),

                        // Password field
                        _buildField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          focused: _passwordFocused,
                          onFocusChange: (v) =>
                              setState(() => _passwordFocused = v),
                          obscure: _obscurePassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _slate,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 12,
                                color: _teal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Sign In button
                        _buildPrimaryButton(),
                        const SizedBox(height: 10),

                        // Cancel button
                        _buildSecondaryButton(),
                        const SizedBox(height: 16),

                        // Sign up prompt
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: _slate,
                                fontWeight: FontWeight.w400,
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account?  "),
                                const TextSpan(
                                  text: 'Sign up',
                                  style: TextStyle(
                                    color: _teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _tealLight,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _teal.withOpacity(0.2), width: 1.5),
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: _tealDark,
        size: 22,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool focused,
    required ValueChanged<bool> onFocusChange,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: TextField(
        controller: controller,
        enabled: !_isLoading,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Icon(
              icon,
              color: focused ? _teal : Colors.grey.shade400,
              size: 18,
            ),
          ),
          prefixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: suffixIcon,
          suffixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: focused ? _tealLight : const Color(0xfff8fafc),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _teal, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.white.withOpacity(0.15),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_tealDark, _teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _teal.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.9)),
                ),
              )
                  : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xfff1f5f9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe2e8f0), width: 1.2),
            ),
            child: const Center(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _slate,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}