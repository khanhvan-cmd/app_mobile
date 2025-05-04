import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:baicuoiki/models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final String baseUrl = 'http://10.0.2.2:5000/api/users'; // URL cơ sở cho API users

  // Map Firebase User to your User model
  User? _userFromFirebaseUser(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      print('Firebase user is null in _userFromFirebaseUser');
      return null;
    }
    print('Mapping Firebase user: uid=${firebaseUser.uid}, email=${firebaseUser.email}, displayName=${firebaseUser.displayName}');
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      username: firebaseUser.displayName ?? 'Unknown',
      avatar: firebaseUser.photoURL, // Lấy avatar từ Firebase
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  // Cập nhật lastActive trong MongoDB
  Future<void> _updateLastActive(String userId) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      await http.put(
        Uri.parse('$baseUrl/$userId/lastActive'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lastActive': DateTime.now().toIso8601String()}),
      );
    } catch (e) {
      print('Error updating lastActive: $e');
    }
  }

  // Lưu thông tin người dùng vào MongoDB
  Future<void> _saveUserToMongoDB(User user) async {
    try {
      final token = await _auth.currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode != 201) {
        print('Failed to save user to MongoDB: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving user to MongoDB: $e');
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      print('Attempting login with email: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign-in result: user=${result.user?.uid}');
      if (result.user == null) {
        print('Login failed: Firebase user is null');
        throw Exception('Login failed: Firebase user is null');
      }

      print('Skipping user reload to avoid plugin errors');
      final user = _userFromFirebaseUser(result.user);
      if (user == null) {
        print('Failed to map Firebase user to User model');
        throw Exception('Failed to map Firebase user to User model');
      }

      await _updateLastActive(user.id); // Cập nhật lastActive
      print('Login successful: userId=${user.id}, email=${user.email}, username=${user.username}');
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('FirebaseAuthException during login: ${e.code} - ${e.message}');
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('Unexpected error during login: $e');
      throw Exception('Unexpected error during login: $e');
    }
  }

  // Register with email, password, and username
  Future<User?> register(String email, String password, String username) async {
    try {
      print('Attempting registration with email: $email, username: $username');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User creation result: user=${result.user?.uid}');
      if (result.user == null) {
        print('Registration failed: Firebase user is null');
        throw Exception('Registration failed: Firebase user is null');
      }

      try {
        print('Updating display name to: $username');
        await result.user!.updateDisplayName(username);
        print('Skipping user reload to avoid plugin errors');
      } catch (e) {
        print('Error updating display name: $e');
      }

      final user = _userFromFirebaseUser(result.user);
      if (user == null) {
        print('Failed to map Firebase user to User model');
        throw Exception('Failed to map Firebase user to User model');
      }

      await _saveUserToMongoDB(user); // Lưu vào MongoDB
      print('Registration successful: userId=${user.id}, email=${user.email}, username=${user.username}');
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      print('Unexpected error during registration: $e');
      throw Exception('Unexpected error during registration: $e');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      print('Attempting Google Sign-In');
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In canceled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print('Google Sign-In failed: Firebase user is null');
        throw Exception('Google Sign-In failed: Firebase user is null');
      }

      print('Google Sign-In result: user=${firebaseUser.uid}');
      final user = _userFromFirebaseUser(firebaseUser);
      if (user == null) {
        print('Failed to map Firebase user to User model');
        throw Exception('Failed to map Firebase user to User model');
      }

      await _saveUserToMongoDB(user); // Lưu vào MongoDB
      await _updateLastActive(user.id); // Cập nhật lastActive
      print('Google Sign-In successful: userId=${user.id}, email=${user.email}, username=${user.username}');
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google Sign-In: ${e.code} - ${e.message}');
      throw Exception('Google Sign-In failed: ${e.message}');
    } catch (e) {
      print('Unexpected error during Google Sign-In: $e');
      throw Exception('Unexpected error during Google Sign-In $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    print('Signing out user');
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}