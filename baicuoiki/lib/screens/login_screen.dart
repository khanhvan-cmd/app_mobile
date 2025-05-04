import 'package:flutter/material.dart';
import 'package:baicuoiki/models/user.dart';
import 'package:baicuoiki/services/auth_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
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

    setState(() => _isLoading = true);
    try {
      print('Attempting to log in with email: $email');
      final user = await _authService.login(email, password);
      if (user != null) {
        print('Login successful, navigating to TaskScreen with userId: ${user.id}');
        Navigator.pushReplacementNamed(
          context,
          '/tasks',
          arguments: user,
        );
      }
    } catch (e) {
      print('Error during login: $e');
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
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A1A3A), Color(0xFF00C4B4), Color(0xFFFF6B8A)],
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
                      SizedBox(height: 40),
                      Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                      SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Card(
                          elevation: 0,
                          color: Color(0xFF1E2A44).withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Color(0xFF1E2A44).withOpacity(0.15),
                              border: Border.all(
                                color: Color(0xFFEEEEEE).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            padding: EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.email, color: Color(0xFFEEEEEE)),
                                    hintText: 'Email',
                                    hintStyle: TextStyle(color: Color(0xFFEEEEEE).withOpacity(0.7)),
                                    filled: true,
                                    fillColor: Color(0xFF1E2A44).withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFFEEEEEE).withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFF00C4B4), width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.lock, color: Color(0xFFEEEEEE)),
                                    hintText: 'Password',
                                    hintStyle: TextStyle(color: Color(0xFFEEEEEE).withOpacity(0.7)),
                                    filled: true,
                                    fillColor: Color(0xFF1E2A44).withOpacity(0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFFEEEEEE).withOpacity(0.3)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Color(0xFF00C4B4), width: 2),
                                    ),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(height: 24),
                                _isLoading
                                    ? CircularProgressIndicator(color: Color(0xFF00C4B4))
                                    : Column(
                                  children: [
                                    ElevatedButton(
                                      onPressed: _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF00C4B4),
                                        padding: EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Color(0xFFEEEEEE).withOpacity(0.2),
                                      ),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
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
                                        'Sign in with Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF1E2A44).withOpacity(0.2),
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: Color(0xFFEEEEEE).withOpacity(0.3)),
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
                        onPressed: () => Navigator.pushNamed(context, '/register'),
                        child: Text(
                          'Don’t have an account? Register',
                          style: TextStyle(
                            color: Color(0xFFEEEEEE),
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
  }
}