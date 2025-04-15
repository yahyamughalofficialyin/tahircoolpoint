import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userId = '';
  String userName = 'User';
  String userEmail = 'No email';
  String userPhone = 'No phone';
  bool isLoading = true;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getString('userId') ?? '';
      });

      if (userId.isNotEmpty) {
        await _fetchUserDetails();
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar('Failed to load user data');
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          userName = userData['name'] ?? 'User';
          userEmail = userData['email'] ?? 'No email';
          userPhone = userData['phone'] ?? 'No phone';
          isLoading = false;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load user data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      final response = await http.put(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/user/email/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': newEmail}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          userEmail = newEmail;
        });
        _showSuccessSnackbar('Email updated successfully');
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update email');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/user/password/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'oldPassword': oldPassword,
          'newPassword': newPassword
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Password updated successfully');
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update password');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _logout() async {
    if (isLoggingOut) return;
    
    setState(() {
      isLoggingOut = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://tahircoolpoint.shaheencodecrafters.com/logout'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId');
        
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to logout');
      }
    } catch (e) {
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildGradientIcon(IconData icon) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return const LinearGradient(
          colors: [Color(0xFFfe0000), Color(0xFF000000)],
          stops: [0.0, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(bounds);
      },
      child: Icon(icon, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: _buildGradientIcon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFfe0000), Color(0xFF000000)],
              stops: [0.0, 0.8],
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello $userName!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          color: Colors.black.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: _buildGradientIcon(Icons.person),
                                title: Text(userName, style: const TextStyle(color: Colors.white)),
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey),
                              ListTile(
                                leading: _buildGradientIcon(Icons.email),
                                title: Text(userEmail, style: const TextStyle(color: Colors.white)),
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey),
                              ListTile(
                                leading: _buildGradientIcon(Icons.phone),
                                title: Text(userPhone, style: const TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 4,
                          color: Colors.black.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: _buildGradientIcon(Icons.edit),
                                title: const Text('Change Email', style: TextStyle(color: Colors.white)),
                                onTap: () => _showChangeEmailDialog(context),
                              ),
                              const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey),
                              ListTile(
                                leading: _buildGradientIcon(Icons.lock),
                                title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                                onTap: () => _showChangePasswordDialog(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: isLoggingOut 
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : _buildGradientIcon(Icons.logout),
                            label: Text(
                              isLoggingOut ? 'Logging out...' : 'Logout',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.7),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _logout,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context) {
    final emailController = TextEditingController(text: userEmail);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: emailController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'New Email',
              labelStyle: const TextStyle(color: Colors.grey),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFfe0000)),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFfe0000),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newEmail = emailController.text.trim();
                if (newEmail == userEmail) {
                  Navigator.of(context).pop();
                  return;
                }
                
                Navigator.of(context).pop();
                await _updateEmail(newEmail);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFfe0000)),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFfe0000)),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFfe0000),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final oldPass = oldPasswordController.text.trim();
                final newPass = newPasswordController.text.trim();
                
                Navigator.of(context).pop();
                await _updatePassword(oldPass, newPass);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}