import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:baicuoiki/firebase_options.dart';
import 'package:baicuoiki/screens/login_screen.dart';
import 'package:baicuoiki/screens/register_screen.dart';
import 'package:baicuoiki/screens/task_screen.dart';
import 'package:baicuoiki/screens/task_detail_screen.dart';
import 'package:baicuoiki/screens/settings_screen.dart';
import 'package:baicuoiki/models/task.dart';

// Lớp quản lý theme tùy chỉnh
class ThemeManager {
  static final ValueNotifier<bool> _isDarkMode = ValueNotifier(false);
  static ValueNotifier<bool> get isDarkMode => _isDarkMode;

  // Gradient cho nền
  static List<Color> get gradientColors {
    return _isDarkMode.value
        ? [Color(0xFF121212), Color(0xFF004D40), Color(0xFF880E4F)] // Tối: đen, xanh đậm, hồng đậm
        : [Color(0xFF0A1A3A), Color(0xFF00C4B4), Color(0xFFFF6B8A)]; // Sáng: gốc
  }

  // Màu thẻ
  static Color get cardColor {
    return _isDarkMode.value
        ? Color(0xFF121212).withOpacity(0.1)
        : Color(0xFF1E2A44).withOpacity(0.1);
  }

  // Màu viền thẻ
  static Color get borderColor {
    return _isDarkMode.value
        ? Colors.white70
        : Color(0xFFEEEEEE);
  }

  // Màu văn bản chính
  static Color get textColor {
    return _isDarkMode.value ? Colors.white70 : Colors.white;
  }

  // Màu văn bản phụ (hint, label)
  static Color get secondaryTextColor {
    return _isDarkMode.value
        ? Colors.white54
        : Color(0xFFEEEEEE).withOpacity(0.7);
  }

  // Màu biểu tượng
  static Color get iconColor {
    return _isDarkMode.value ? Colors.white70 : Color(0xFFEEEEEE);
  }

  // Màu nút chính
  static Color get buttonColor {
    return _isDarkMode.value ? Colors.teal : Color(0xFF00C4B4);
  }

  // Màu viền nút phụ
  static Color get secondaryButtonBorderColor {
    return _isDarkMode.value
        ? Colors.white30
        : Color(0xFFEEEEEE).withOpacity(0.3);
  }

  // Màu viền TextField khi focus
  static Color get focusedBorderColor {
    return _isDarkMode.value ? Colors.teal : Color(0xFF00C4B4);
  }

  // Màu viền TextField khi enable
  static Color get enabledBorderColor {
    return _isDarkMode.value
        ? Colors.white30
        : Color(0xFFEEEEEE).withOpacity(0.3);
  }

  // Chuyển đổi theme
  static void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
  }
}

Future<void> _setupFCM() async {
  final fcm = FirebaseMessaging.instance;
  await fcm.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );
  final token = await fcm.getToken();
  print('FCM Token: $token');
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase khởi tạo thành công');
    await _setupFCM();
  } catch (e) {
    print('Lỗi khi khởi tạo Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeManager.isDarkMode,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          title: 'Task Manager',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Poppins'),
              bodyMedium: TextStyle(fontFamily: 'Poppins'),
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
              displaySmall: TextStyle(fontFamily: 'Poppins'),
              headlineLarge: TextStyle(fontFamily: 'Poppins'),
              headlineMedium: TextStyle(fontFamily: 'Poppins'),
              headlineSmall: TextStyle(fontFamily: 'Poppins'),
              titleLarge: TextStyle(fontFamily: 'Poppins'),
              titleMedium: TextStyle(fontFamily: 'Poppins'),
              titleSmall: TextStyle(fontFamily: 'Poppins'),
              labelLarge: TextStyle(fontFamily: 'Poppins'),
              labelMedium: TextStyle(fontFamily: 'Poppins'),
              labelSmall: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.teal,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: const TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Poppins'),
              bodyMedium: TextStyle(fontFamily: 'Poppins'),
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
              displaySmall: TextStyle(fontFamily: 'Poppins'),
              headlineLarge: TextStyle(fontFamily: 'Poppins'),
              headlineMedium: TextStyle(fontFamily: 'Poppins'),
              headlineSmall: TextStyle(fontFamily: 'Poppins'),
              titleLarge: TextStyle(fontFamily: 'Poppins'),
              titleMedium: TextStyle(fontFamily: 'Poppins'),
              titleSmall: TextStyle(fontFamily: 'Poppins'),
              labelLarge: TextStyle(fontFamily: 'Poppins'),
              labelMedium: TextStyle(fontFamily: 'Poppins'),
              labelSmall: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginScreen(),
            '/register': (context) => RegisterScreen(),
            '/tasks': (context) => TaskScreen(),
            '/task_detail': (context) => TaskDetailScreen(
              task: ModalRoute.of(context)!.settings.arguments as Task,
            ),
            '/settings': (context) => SettingsScreen(),
          },
        );
      },
    );
  }
}