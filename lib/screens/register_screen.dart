import 'package:flutter/material.dart';
import 'package:login_jwt/providers/auth_provider.dart';
import 'package:login_jwt/screens/login_screen.dart';
import 'package:login_jwt/screens/profile_screen.dart';
import 'package:login_jwt/widgets/custom_button.dart';
import 'package:login_jwt/widgets/custom_text_field.dart';
import 'package:login_jwt/widgets/message_banner.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecialChar =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? Colors.green.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green.shade800 : Colors.grey.shade600,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1_rounded,
                                  size: 38,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Register a new account to get started',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error / Success Banners
                        if (authProvider.errorMessage != null)
                          MessageBanner(
                            message: authProvider.errorMessage!,
                            isError: true,
                            onClose: () => authProvider.clearMessages(),
                          ),

                        if (authProvider.successMessage != null)
                          MessageBanner(
                            message: authProvider.successMessage!,
                            isError: false,
                            onClose: () => authProvider.clearMessages(),
                          ),

                        // Full Name Field
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'John Doe',
                          prefixIcon: Icons.person_outline_rounded,
                          enabled: !authProvider.isLoading,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your full name.';
                            }
                            if (value.trim().length < 2) {
                              return 'Name must be at least 2 characters long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Address Field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'john.doe@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !authProvider.isLoading,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an email address.';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+')
                                .hasMatch(value.trim())) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          enabled: !authProvider.isLoading,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password.';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters long.';
                            }
                            if (!RegExp(r'[A-Z]').hasMatch(value)) {
                              return 'Must contain at least 1 uppercase letter.';
                            }
                            if (!RegExp(r'[a-z]').hasMatch(value)) {
                              return 'Must contain at least 1 lowercase letter.';
                            }
                            if (!RegExp(r'[0-9]').hasMatch(value)) {
                              return 'Must contain at least 1 number.';
                            }
                            if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                              return 'Must contain at least 1 special character.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),

                        // Password Strength Checks
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password requirements:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildPasswordRequirement(
                                  'At least 8 characters long', _hasMinLength),
                              _buildPasswordRequirement(
                                  'At least 1 uppercase letter (A-Z)',
                                  _hasUppercase),
                              _buildPasswordRequirement(
                                  'At least 1 lowercase letter (a-z)',
                                  _hasLowercase),
                              _buildPasswordRequirement(
                                  'At least 1 numeric digit (0-9)', _hasDigit),
                              _buildPasswordRequirement(
                                  'At least 1 special character (!@#\$%...)',
                                  _hasSpecialChar),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_reset_outlined,
                          obscureText: _obscureConfirmPassword,
                          enabled: !authProvider.isLoading,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleRegister(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password.';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Register Button
                        CustomButton(
                          text: 'Create Account',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: authProvider.isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 20),

                        // Back to Login Link (Wrapped)
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () {
                                        authProvider.clearMessages();
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (_) => const LoginScreen(),
                                          ),
                                        );
                                      },
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
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
          ),
        ),
      ),
    );
  }
}
