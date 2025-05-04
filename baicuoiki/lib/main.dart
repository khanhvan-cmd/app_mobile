import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:baicuoiki/firebase_options.dart';
import 'package:baicuoiki/screens/login_screen.dart';
import 'package:baicuoiki/screens/register_screen.dart';
import 'package:baicuoiki/screens/task_screen.dart';
import 'package:baicuoiki/screens/task_detail_screen.dart';
import 'package:baicuoiki/screens/settings_screen.dart'; // Thêm import mới
import 'package:baicuoiki/models/task.dart';

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
  // TODO: Gửi token này đến backend để lưu trữ
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('Firebase khởi tạo thành công');
    await _setupFCM(); // Khởi tạo FCM
  } catch (e) {
    print('Lỗi khi khởi tạo Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/tasks': (context) => TaskScreen(),
        '/task_detail': (context) => TaskDetailScreen(
          task: ModalRoute.of(context)!.settings.arguments as Task,
        ),
        '/settings': (context) => SettingsScreen(), // Thêm route mới
      },
    );
  }
}