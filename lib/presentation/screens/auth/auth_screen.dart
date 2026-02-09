import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import '../../widgets/custom_painters/smoke_painter.dart';
import '../../../core/api_client.dart';
import '../../../core/auth_service.dart';

/// Single auth page: one card with Login | Sign up tabs.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authService,
    required this.onSuccess,
    required this.onToggleTheme,
  });

  final AuthService authService;
  final VoidCallback onSuccess;
  final VoidCallback onToggleTheme;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _smokeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SmokeBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: widget.onToggleTheme,
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: Theme.of(context).brightness == Brightness.dark
                        ? 'Light mode'
                        : 'Dark mode',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'VisionArt',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your Context, Your Art',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              // Card grows to fill remaining space so keyboard doesn't cause overflow
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.cardBackgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Colorful smoke blobs behind content
                          Positioned.fill(
                            child: CustomPaint(
                              painter: CardSmokePainter(
                                animation: _smokeController,
                              ),
                            ),
                          ),
                          // Tabs + content on top
                          Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                indicatorColor: AppColors.primaryPurple,
                                indicatorWeight: 3,
                                labelColor: AppColors.primaryPurple,
                                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                tabs: const [
                                  Tab(text: 'Login'),
                                  Tab(text: 'Sign up'),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _LoginCard(
                                      authService: widget.authService,
                                      onSuccess: widget.onSuccess,
                                      onGoToSignUp: () =>
                                          _tabController.animateTo(1),
                                    ),
                                    _SignUpCard(
                                      authService: widget.authService,
                                      onSuccess: widget.onSuccess,
                                      onGoToLogin: () => _tabController.animateTo(0),
                                    ),
                                  ],
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
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard({
    required this.authService,
    required this.onSuccess,
    required this.onGoToSignUp,
  });

  final AuthService authService;
  final VoidCallback onSuccess;
  final VoidCallback onGoToSignUp;

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await widget.authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        setState(() => _loading = false);
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, String hint, {IconData? icon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: focusBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            decoration: _inputDecoration('Email', 'Enter your email', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: _inputDecoration('Password', 'Enter password', icon: Icons.lock_outline_rounded),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onGoToSignUp,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: 'Sign up',
                    style: TextStyle(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpCard extends StatefulWidget {
  const _SignUpCard({
    required this.authService,
    required this.onSuccess,
    required this.onGoToLogin,
  });

  final AuthService authService;
  final VoidCallback onSuccess;
  final VoidCallback onGoToLogin;

  @override
  State<_SignUpCard> createState() => _SignUpCardState();
}

class _SignUpCardState extends State<_SignUpCard> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      await widget.authService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        setState(() => _loading = false);
        widget.onSuccess();
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, String hint, {IconData? icon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant) : null,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: focusBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('Name', 'Your full name', icon: Icons.person_outline_rounded),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: _inputDecoration('Email', 'Enter your email', icon: Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: _inputDecoration('Password', 'Create password', icon: Icons.lock_outline_rounded),
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onGoToLogin,
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Login',
                    style: TextStyle(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
