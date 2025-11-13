import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';
import 'package:pbx_gui/create_account_widget.dart';
import 'package:pbx_gui/forgot_password_widget.dart';
import 'package:pbx_gui/models/user_models.dart';
import 'package:pbx_gui/services/auth_service.dart';

// Model
class LoginPageModel {
  // State fields for stateful widgets in this page.

  // State field(s) for emailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;

  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;

  bool isLoading = false;
  String? errorMessage;

  void initState(BuildContext context) {
    passwordVisibility = false;
    emailAddressTextControllerValidator = _emailValidator;
    passwordTextControllerValidator = _passwordValidator;
  }

  String? _emailValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Password is required';
    }
    if (val.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();
  }
}

class LoginPageWidget extends StatefulWidget {
  final String title;
  final String logoUrl;
  final Function(AuthResult)? onLoginSuccess;
  final bool showGoogleSignIn;
  final bool showCreateAccount;
  final bool showForgotPassword;
  final String? initialEmail;

  const LoginPageWidget({
    super.key,
    required this.title,
    required this.logoUrl,
    this.onLoginSuccess,
    this.showGoogleSignIn = true,
    this.showCreateAccount = true,
    this.showForgotPassword = true,
    this.initialEmail,
  });

  static String routeName = 'LoginPage';
  static String routePath = '/loginPage';

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  late LoginPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _model = LoginPageModel();
    _model.initState(context);
    _initializeControllers();
  }

  void _initializeControllers() {
    _model.emailAddressTextController ??= TextEditingController(
      text: widget.initialEmail,
    );
    _model.emailAddressFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
  }

  Future<void> _handleEmailSignIn() async {
    if (_model.emailAddressTextController?.text == null ||
        _model.passwordTextController?.text == null) {
      return;
    }

    setState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });

    try {
      final result = await _authService.signInWithEmail(
        email: _model.emailAddressTextController!.text.trim(),
        password: _model.passwordTextController!.text,
      );

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(result);
      }
    } catch (e) {
      setState(() {
        _model.errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _model.isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    print('handle google');
    setState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });

    try {
      print('Trigger the authentication flow');

      final AuthResult result = await _authService.signInWithGoogle();
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(result);
      }
    } catch (e) {
      setState(() {
        _model.errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _model.isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: scaffoldKey,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildHeader(), _buildLoginForm()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 70, 0, 32),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 16),
            _buildLogo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        fadeInDuration: const Duration(milliseconds: 500),
        fadeOutDuration: const Duration(milliseconds: 500),
        imageUrl: widget.logoUrl,
        width: 96,
        height: 96,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLoginForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue to your account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_model.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _model.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 24),
                _buildSignInButton(),
                if (widget.showGoogleSignIn) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: colorScheme.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGoogleSignInButton(),
                ],
                if (widget.showCreateAccount || widget.showForgotPassword) ...[
                  const SizedBox(height: 24),
                  if (widget.showCreateAccount) _buildCreateAccountLink(),
                  if (widget.showForgotPassword) ...[
                    const SizedBox(height: 12),
                    _buildForgotPasswordButton(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _model.emailAddressTextController,
      focusNode: _model.emailAddressFocusNode,
      autofocus: false,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'your@email.com',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: _model.emailAddressTextControllerValidator != null
          ? (val) => _model.emailAddressTextControllerValidator!(context, val)
          : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _model.passwordTextController,
      focusNode: _model.passwordFocusNode,
      autofocus: false,
      autofillHints: const [AutofillHints.password],
      obscureText: !_model.passwordVisibility,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _model.passwordVisibility
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(
            () => _model.passwordVisibility = !_model.passwordVisibility,
          ),
        ),
      ),
      validator: _model.passwordTextControllerValidator != null
          ? (val) => _model.passwordTextControllerValidator!(context, val)
          : null,
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _model.isLoading ? null : _handleEmailSignIn,
        child: _model.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Sign In'),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    print('build google');
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _model.isLoading ? null : _handleGoogleSignIn,
        icon: Image.network(
          'https://www.google.com/favicon.ico',
          width: 20,
          height: 20,
        ),
        label: const Text('Continue with Google'),
      ),
    );
  }

  Widget _buildCreateAccountLink() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateAccountWidget(
              title: widget.title,
              logoUrl: widget.logoUrl,
              onAccountCreated: widget.onLoginSuccess,
              onBackToLogin: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            children: [
              const TextSpan(text: 'Don\'t have an account? '),
              TextSpan(
                text: 'Create Account',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ForgotPasswordWidget(
              title: widget.title,
              logoUrl: widget.logoUrl,
              onBackToLogin: () => Navigator.of(context).pop(),
            ),
          ),
        );
      },
      child: const Text('Forgot password?'),
    );
  }
}
