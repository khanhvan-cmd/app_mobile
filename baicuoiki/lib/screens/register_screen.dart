import 'package:flutter/material.dart';
import 'package:baicuoiki/models/user.dart';
import 'package:baicuoiki/services/auth_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:baicuoiki/main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _roleController = TextEditingController(); // Thêm controller cho vai trò
  bool _isLoading = false;

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();
    final role = _roleController.text.trim(); // Lấy giá trị vai trò
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên đăng nhập')),
      );
      return;
    }
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập email hợp lệ')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu phải có ít nhất 6 ký tự')),
      );
      return;
    }
    if (role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn vai trò')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Attempting to register with email: $email, role: $role');
      final user = await _authService.register(email, password, username, role); // Truyền vai trò vào hàm register
      if (user != null) {
        print('Registration successful, navigating to TaskScreen with userId: ${user.id}');
        Navigator.pushReplacementNamed(
          context,
          '/tasks',
          arguments: user,
        );
      }
    } catch (e) {
      print('Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      print('Attempting to sign in with Google');
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        print('Google Sign-In successful, navigating to TaskScreen with userId: ${user.id}');
        Navigator.pushReplacementNamed(
          context,
          '/tasks',
          arguments: user,
        );
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeManager.isDarkMode,
      builder: (context, isDarkMode, child) {
        return Scaffold(
          body: Container(
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ThemeManager.gradientColors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: AnimationLimiter(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 800),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                        children: [
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: ThemeManager.textColor,
                                    fontFamily: 'Roboto',
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 15.0,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                  size: 36,
                                  color: ThemeManager.textColor,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: ThemeManager.cardColor.withOpacity(0.3),
                                  shape: CircleBorder(),
                                  padding: EdgeInsets.all(12),
                                  elevation: 4,
                                  shadowColor: Colors.black.withOpacity(0.2),
                                ),
                                onPressed: ThemeManager.toggleTheme,
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
                            child: Card(
                              elevation: 0,
                              color: ThemeManager.cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: ThemeManager.cardColor,
                                  border: Border.all(
                                    color: ThemeManager.borderColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                padding: EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.person, color: ThemeManager.iconColor),
                                        hintText: 'Username',
                                        hintStyle: TextStyle(color: ThemeManager.secondaryTextColor),
                                        filled: true,
                                        fillColor: ThemeManager.cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.enabledBorderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.focusedBorderColor, width: 2),
                                        ),
                                      ),
                                      style: TextStyle(color: ThemeManager.textColor),
                                    ),
                                    SizedBox(height: 16),
                                    TextField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.email, color: ThemeManager.iconColor),
                                        hintText: 'Email',
                                        hintStyle: TextStyle(color: ThemeManager.secondaryTextColor),
                                        filled: true,
                                        fillColor: ThemeManager.cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.enabledBorderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.focusedBorderColor, width: 2),
                                        ),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      style: TextStyle(color: ThemeManager.textColor),
                                    ),
                                    SizedBox(height: 16),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.lock, color: ThemeManager.iconColor),
                                        hintText: 'Password',
                                        hintStyle: TextStyle(color: ThemeManager.secondaryTextColor),
                                        filled: true,
                                        fillColor: ThemeManager.cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.enabledBorderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.focusedBorderColor, width: 2),
                                        ),
                                      ),
                                      style: TextStyle(color: ThemeManager.textColor),
                                    ),
                                    SizedBox(height: 16),
                                    TextField(
                                      controller: _roleController, // Thêm trường vai trò
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.work, color: ThemeManager.iconColor),
                                        hintText: 'Role',
                                        hintStyle: TextStyle(color: ThemeManager.secondaryTextColor),
                                        filled: true,
                                        fillColor: ThemeManager.cardColor,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.enabledBorderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: ThemeManager.focusedBorderColor, width: 2),
                                        ),
                                      ),
                                      style: TextStyle(color: ThemeManager.textColor),
                                    ),
                                    SizedBox(height: 24),
                                    _isLoading
                                        ? CircularProgressIndicator(color: ThemeManager.buttonColor)
                                        : Column(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _register,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ThemeManager.buttonColor,
                                            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: ThemeManager.borderColor.withOpacity(0.2),
                                          ),
                                          child: Text(
                                            'Register',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: ThemeManager.textColor,
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: _signInWithGoogle,
                                          icon: Image.asset(
                                            'assets/y-nghia-gg-trong-cac-thuat-ngu-hang-ngay-1.webp',
                                            height: 24,
                                            width: 24,
                                            fit: BoxFit.contain,
                                          ),
                                          label: Text(
                                            'Sign up with Google',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: ThemeManager.textColor,
                                              fontFamily: 'Roboto',
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ThemeManager.cardColor.withOpacity(0.2),
                                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(color: ThemeManager.secondaryButtonBorderColor),
                                            ),
                                            elevation: 0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: Text(
                              'Already have an account? Login',
                              style: TextStyle(
                                color: ThemeManager.borderColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}