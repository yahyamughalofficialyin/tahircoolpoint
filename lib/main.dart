import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tahircoolpoint/login.dart';
import 'package:video_player/video_player.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'signup.dart';
import 'home.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseInitialized = false;
  
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyBOspHYd4CY42dK0C8klf0ovVoFAWyUeKg",
          authDomain: "tahircoolpoint-75ab0.firebaseapp.com",
          projectId: "tahircoolpoint-75ab0",
          storageBucket: "tahircoolpoint-75ab0.firebasestorage.app",
          messagingSenderId: "606853221987",
          appId: "1:606853221987:web:3c90d6e196b380d9a93256",
          measurementId: "G-0TGGW0XBFT",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    firebaseInitialized = true;
  } catch (e) {
    print('Firebase initialization error: $e');
    firebaseInitialized = false;
  }
  
  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MyApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(firebaseInitialized: firebaseInitialized),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final bool firebaseInitialized;
  
  const SplashScreen({super.key, required this.firebaseInitialized});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('videos/splash.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        if (widget.firebaseInitialized) {
          _checkIfLoggedIn(); // Only check login if Firebase is initialized
        } else {
          _showFirebaseError();
        }
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        // Navigation is now handled in _checkIfLoggedIn or _showFirebaseError
      }
    });
  }

  void _showFirebaseError() {
    setState(() {
      _showError = true;
    });
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    // Wait until the video is finished playing
    while (_controller.value.position < _controller.value.duration) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (userId != null && userId.isNotEmpty) {
      Get.off(() => Home()); // Navigate to Home if logged in
    } else {
      Get.off(() => Login()); // Navigate to Login if not logged in
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 20),
                  Text(
                    'Firebase Connection Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please check your internet connection and try again',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // You could try to reinitialize Firebase here
                      // Or simply exit the app
                      // For now, we'll just show the error
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : _controller.value.isInitialized
              ? Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              : Center(child: CircularProgressIndicator()),
    );
  }
}