import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'auth_controller.dart';
import '../../core/constants/app_constants.dart';

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF121212), Color(0xFF1E1E2C)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo / Icon
              Icon(
                Icons.auto_awesome,
                size: 80,
                color: Theme.of(context).primaryColor,
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 24),
              
              // App Name
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1.5,
                ),
              ).animate().fadeIn().slideY(begin: 0.3),
              
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                AppConstants.tagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
              ).animate().fadeIn(delay: 200.ms),
              
              const Spacer(),

              // Error Message
              if (authState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Login Failed: ${authState.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Login Button
              ElevatedButton.icon(
                onPressed: authState.isLoading 
                  ? null 
                  : () => ref.read(authControllerProvider.notifier).signInAnonymously(),
                icon: authState.isLoading 
                  ? const SizedBox.shrink() 
                  : const Icon(Icons.login),
                label: authState.isLoading
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2)
                    )
                  : const Text("Get Started"),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 1.0),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}