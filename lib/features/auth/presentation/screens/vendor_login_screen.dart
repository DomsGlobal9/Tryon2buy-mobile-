import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../routes/app_router.dart';
import '../../data/auth_repository.dart';

/// Unified Authentication Portal matching the web Studio & B2B portal design.
///
/// Strictly uses Email & Password authentication:
///   * **Merchant Studio** — Warm ivory (#FAF7F2), EB Garamond serif typography,
///     black CTA, tab switching between Sign In and Create Account, and link to B2B portal.
///   * **B2B Client Portal** — Obsidian velvet (#140F0C), gold accent CTA (#C4933F),
///     and link back to Merchant Studio.
class VendorLoginScreen extends StatefulWidget {
  final String initialType;

  /// Open on the "Create account" tab (merchant portal only).
  final bool initialRegistering;

  const VendorLoginScreen({
    super.key,
    this.initialType = 'normal',
    this.initialRegistering = false,
  });

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _authRepo = AuthRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();

  late bool _isB2b = widget.initialType == 'b2b';
  late bool _isRegistering = widget.initialRegistering && !_isB2b;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Registration needs the owner's name and the boutique name, as on the
    // website's "Create Account" tab.
    final problem = Validators.email(email) ??
        Validators.password(password) ??
        (!_isB2b && _isRegistering
            ? (Validators.name(_nameController.text) ??
                (_storeNameController.text.trim().isEmpty
                    ? 'Please enter your boutique or store name.'
                    : null))
            : null);
    if (problem != null) {
      UiHelpers.showSnackBar(context, problem, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isB2b) {
        // B2B Enterprise Client Login
        final res = await _authRepo.loginB2bClient(
          email: email,
          password: password,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res.success) {
          _finishSignIn(workspaceRoute: AppRouter.b2bDigitize);
        } else {
          UiHelpers.showSnackBar(
            context,
            res.error ?? 'Access denied — credentials may not have B2B enterprise permissions.',
            isError: true,
          );
        }
      } else {
        // Merchant Studio Login / Registration
        final res = _isRegistering
            ? await _authRepo.registerVendor(
                email: email,
                password: password,
                name: _nameController.text.trim(),
                storeName: _storeNameController.text.trim(),
              )
            : await _authRepo.loginVendor(email: email, password: password);

        if (!mounted) return;
        setState(() => _isLoading = false);

        if (res.success) {
          _finishSignIn(workspaceRoute: AppRouter.vendorWorkspace);
        } else {
          UiHelpers.showSnackBar(
            context,
            res.error ?? (_isRegistering ? 'Registration failed' : 'Login failed'),
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiHelpers.showSnackBar(context, 'Authentication failed. Please try again.', isError: true);
      }
    }
  }

  void _finishSignIn({String? workspaceRoute}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (_) => false);
    if (workspaceRoute != null) Navigator.pushNamed(context, workspaceRoute);
  }

  Future<void> _continueAsGuest() async {
    await _authRepo.enableGuestMode();
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isB2b ? const Color(0xFF140F0C) : const Color(0xFFFAF7F2);
    final isDark = _isB2b;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF1A1410),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        color: bgColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: isDark ? _buildB2bPortal() : _buildMerchantStudio(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MERCHANT STUDIO (Normal Mode) - Matching web VendorAuth.jsx
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildMerchantStudio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Merchant Studio',
          style: GoogleFonts.ebGaramond(
            fontSize: 34,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1410),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        const Text(
          'Sign in to manage your digital catalog and virtual try-ons.',
          style: TextStyle(
            color: Color(0xFF8C8278),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Tab Switcher (SIGN IN / CREATE ACCOUNT)
        Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 1,
                color: const Color(0x1F1A1410),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isRegistering = false),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: !_isRegistering ? const Color(0xFF1A1410) : const Color(0xFF8C8278),
                          ),
                        ),
                      ),
                      Container(
                        height: 2.5,
                        width: 58,
                        color: !_isRegistering ? const Color(0xFF1A1410) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: () => setState(() => _isRegistering = true),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: _isRegistering ? const Color(0xFF1A1410) : const Color(0xFF8C8278),
                          ),
                        ),
                      ),
                      Container(
                        height: 2.5,
                        width: 140,
                        color: _isRegistering ? const Color(0xFF1A1410) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Create Account fields (if registering)
        if (_isRegistering) ...[
          _buildField(
            label: 'OWNER NAME',
            hint: 'e.g. Jane Doe',
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 18),
          _buildField(
            label: 'BOUTIQUE NAME',
            hint: 'e.g. Heritage Coutures',
            controller: _storeNameController,
            prefixIcon: Icons.store_outlined,
          ),
          const SizedBox(height: 18),
        ],

        // Email field
        _buildField(
          label: 'EMAIL ADDRESS',
          hint: 'vendor@store.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 18),

        // Password field
        _buildField(
          label: 'PASSWORD',
          hint: '••••••••',
          controller: _passwordController,
          obscureText: _obscurePassword,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: const Color(0xFF8C8278),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 28),

        // Submit Button (SIGN IN TO STUDIO ->)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1410),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegistering ? 'CREATE MERCHANT ACCOUNT' : 'SIGN IN TO STUDIO',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
          ),
        ),

        // Divider & B2B Portal Link
        const SizedBox(height: 36),
        Container(
          height: 1,
          color: const Color(0x141A1410),
        ),
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              const Text(
                'Are you a B2B or wholesale client?',
                style: TextStyle(
                  color: Color(0xFF8C8278),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _isB2b = true),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Access B2B Client Portal',
                        style: TextStyle(
                          color: Color(0xFF1A1410),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF1A1410),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Browse Storefront as Guest
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _continueAsGuest,
            icon: const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: Color(0xFF8C8278),
            ),
            label: const Text(
              'Browse Storefront as Guest',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C8278),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // B2B CLIENT PORTAL (Enterprise Mode) - Matching web ClientAuth.jsx
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildB2bPortal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header
        const Center(
          child: Text(
            'B2B CLIENT PORTAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
              color: Color(0xFF8C8278),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Single Header with side dividers (Client Login)
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'CLIENT LOGIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        const Center(
          child: Text(
            'Enterprise workspace for garment digitization & wholesale catalog.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB5A799),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Business Email field
        _buildField(
          label: 'BUSINESS EMAIL',
          hint: 'client@brand.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          isDark: true,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 18),

        // Password field
        _buildField(
          label: 'PASSWORD',
          hint: '••••••••',
          controller: _passwordController,
          obscureText: _obscurePassword,
          isDark: true,
          prefixIcon: Icons.lock_outline_rounded,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 20,
              color: const Color(0xFF8C8278),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 28),

        // Submit Button (ACCESS PORTAL -> in luxury gold)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC4933F),
              foregroundColor: const Color(0xFF140F0C),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF140F0C)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'ACCESS PORTAL',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                          color: Color(0xFF140F0C),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF140F0C)),
                    ],
                  ),
          ),
        ),

        // Link back to Merchant Studio
        const SizedBox(height: 36),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const Text(
                'ARE YOU A MERCHANT?',
                style: TextStyle(
                  color: Color(0xFF8C8278),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _isB2b = false),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Go to Studio Portal',
                        style: TextStyle(
                          color: Color(0xFFC4933F),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFFC4933F),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Browse Storefront as Guest
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: _continueAsGuest,
            icon: const Icon(
              Icons.storefront_outlined,
              size: 16,
              color: Color(0xFF8C8278),
            ),
            label: const Text(
              'Browse Storefront as Guest',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8C8278),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Clean Input Field with Uppercase Tracking Label
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    bool isDark = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    final fieldBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0x1F1A1410);
    final iconColor = isDark ? const Color(0xFFC4933F) : const Color(0xFF8C8278);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1410);
    final hintColor = isDark ? const Color(0xFF7A6F65) : const Color(0xFFA0988F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: isDark ? const Color(0xFF9E948A) : const Color(0xFF8C8278),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(prefixIcon, size: 19, color: iconColor),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (suffixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffixIcon,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
