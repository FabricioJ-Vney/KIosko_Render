// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'role_selection_screen.dart';
import 'project_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'Student';
  final TextEditingController _idController = TextEditingController();

  void _navigateToRoleSelection(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RoleSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Kritik',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 48),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(hintText: 'ID Institucional / Usuario'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(hintText: 'Selecciona tu Rol'),
                items: const [
                  DropdownMenuItem(value: 'Student', child: Text('Alumno / Proyectista')),
                  DropdownMenuItem(value: 'Evaluator', child: Text('Evaluador / Juez')),
                  DropdownMenuItem(value: 'Admin', child: Text('Administrador')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_idController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor ingresa tu ID')),
                    );
                    return;
                  }
                  // In a real app, call ApiService.login here
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => ProjectListScreen(role: _selectedRole)),
                  );
                },
                child: const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.borderColor, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Text(
                        'o',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.borderColor, thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _navigateToRoleSelection(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.backgroundWhite,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: const BorderSide(
                      color: AppColors.textPrimary,
                      width: 1.0,
                    ),
                  ),
                ),
                child: const Text('Acceso como Invitado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
