import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isRegistering = false;
  String _selectedRole = 'arborist';
  bool _isOnline = false;
  
  @override
  void initState() {
    super.initState();
    // Set default admin credentials for demo
    _emailController.text = 'admin@arborist.com';
    _passwordController.text = 'admin123';
    
    // Check connectivity status
    _checkConnectivity();
  }
  
  Future<void> _checkConnectivity() async {
    final isOnline = FirebaseService.isOnline;
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _handleSubmit() async {
    print('Login attempt started...'); // Debug log
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed'); // Debug log
      return;
    }
    
    print('Form validation passed, attempting login...'); // Debug log
    print('Email: ${_emailController.text}'); // Debug log
    print('Password length: ${_passwordController.text.length}'); // Debug log
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      bool success;
      
      if (_isRegistering) {
        print('Attempting registration...'); // Debug log
        success = await AuthService.register(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
          role: _selectedRole,
        );
        
        if (success) {
          if (_isOnline) {
            NotificationService.showSuccess(context, 'Registration successful! You are now signed in.');
          } else {
            NotificationService.showSuccess(context, 'Registration successful! Please log in.');
            setState(() {
              _isRegistering = false;
            });
          }
        } else {
          NotificationService.showError(context, 'Registration failed. Please try again.');
        }
      } else {
        print('Attempting login...'); // Debug log
        success = await AuthService.login(
          _emailController.text,
          _passwordController.text,
        );
        
        print('Login result: $success'); // Debug log
        
        if (success) {
          if (_isOnline) {
            NotificationService.showSuccess(context, 'Login successful!');
          } else {
            NotificationService.showSuccess(context, 'Login successful! (Offline mode)');
          }
          // Navigation will be handled by AuthGate
        } else {
          NotificationService.showError(context, 'Invalid email or password.');
        }
      }
    } catch (e) {
      print('Login error caught: $e'); // Debug log
      String errorMessage = 'An error occurred: $e';
      
      // Provide more specific error messages for Firebase
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email address.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'An account with this email already exists.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use at least 6 characters.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      NotificationService.showError(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green, Colors.lightGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Title
                        const Icon(
                          Icons.forest,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Arborist Assistant',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegistering ? 'Create Account' : 'Sign In',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        // Connection Status
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isOnline ? Colors.green : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isOnline ? Icons.wifi : Icons.wifi_off,
                                size: 16,
                                color: _isOnline ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isOnline ? 'Online - Firebase Sync Available' : 'Offline - Local Mode Only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isOnline ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Form Fields
                        if (_isRegistering) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        
                        if (_isRegistering) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                              prefixIcon: Icon(Icons.work),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'arborist', child: Text('Arborist')),
                              DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                              DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
                                : Text(_isRegistering ? 'Register' : 'Sign In'),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Toggle Register/Login
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isRegistering = !_isRegistering;
                                  });
                                },
                          child: Text(
                            _isRegistering
                                ? 'Already have an account? Sign In'
                                : 'Don\'t have an account? Register',
                          ),
                        ),
                        
                        if (!_isRegistering) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Demo Credentials:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Text(
                            'Email: admin@arborist.com\nPassword: admin123',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
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
