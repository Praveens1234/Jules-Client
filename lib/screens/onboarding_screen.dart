import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jules_client/screens/dashboard_screen.dart';
import 'package:jules_client/services/storage_service.dart';
import 'package:jules_client/theme/app_theme.dart';
import 'package:jules_client/widgets/glass_container.dart';
import 'package:jules_client/widgets/neon_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _apiKeyController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.saveUserProfile(
        _nameController.text, 
        _emailController.text,
        _mobileController.text,
      );
      await storage.saveApiKey(_apiKeyController.text);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.2),
                boxShadow: const [BoxShadow(blurRadius: 100, spreadRadius: 50, color: AppTheme.primaryColor)],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.15),
                boxShadow: const [BoxShadow(blurRadius: 80, spreadRadius: 40, color: AppTheme.accentColor)],
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "JULES",
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8),
                  ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    "THE ULTIMATE CLIENT",
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), letterSpacing: 4),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),

                  const SizedBox(height: 60),

                  GlassContainer(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text("Welcome, Developer", style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(hintText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => v!.isEmpty ? "Name is required" : null,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(hintText: "Email Address", prefixIcon: Icon(Icons.email_outlined)),
                            validator: (v) => v!.isEmpty ? "Email is required" : null,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _mobileController,
                            decoration: const InputDecoration(hintText: "Contact Mobile", prefixIcon: Icon(Icons.phone_android)),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? "Mobile number is required" : null,
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _apiKeyController,
                            decoration: const InputDecoration(hintText: "Jules API Key", prefixIcon: Icon(Icons.vpn_key_outlined)),
                            obscureText: true,
                            validator: (v) => v!.isEmpty ? "API Key is required" : null,
                          ),
                          const SizedBox(height: 30),

                          NeonButton(
                            text: "INITIALIZE SYSTEM",
                            onPressed: _submit,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
