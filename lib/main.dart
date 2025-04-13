import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tahircoolpoint/login.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'signup.dart';
import 'home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _showError = false;
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller with 3 second duration
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    );
    
    // Create scale animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.7, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(_animationController);
    
    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Start animation
    _animationController.forward().whenComplete(() {
      setState(() {
        _animationCompleted = true;
      });
      // Check Firebase status and proceed accordingly
      if (widget.firebaseInitialized) {
        _checkIfLoggedIn();
      } else {
        _showFirebaseError();
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

    if (userId != null && userId.isNotEmpty) {
      Get.off(() => Home()); // Navigate to Home if logged in
    } else {
      Get.off(() => Login()); // Navigate to Login if not logged in
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background image
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.2),
              BlendMode.darken,
            ),
            child: Image.asset(
              'images/bg.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Colors.black.withOpacity(0.1),
            ),
          ),
          
          if (_showError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 20),
                  Text(
                    'Firebase Connection Failed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Please check your internet connection and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
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
          else
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Image.asset(
                        'images/icon.png',
                        width: 150,
                        height: 150,
                      ),
                    ),
                  );
                },
              ),
            ),
          
          if (_animationCompleted && !_showError)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}