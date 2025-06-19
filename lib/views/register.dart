import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../view_models/auth_view_model.dart';

class Register extends ConsumerWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(authViewModelProvider);

    final fC = TextEditingController();
    final lC = TextEditingController();
    final eC = TextEditingController();
    final phC = TextEditingController();
    final uC = TextEditingController();
    final pC = TextEditingController();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5E151D), // #5E151D
              Color(0xFFF4CED9), // #F4CED9
            ],
          ),
        ),
        child: Column(
          children: [
            // Título centrado en la parte superior
            Container(
              padding: const EdgeInsets.only(top: 60),
              alignment: Alignment.center,
              child: const Text(
                'Registro',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Contenido del formulario
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // Campos del formulario
                    _buildWhiteInput(fC, 'Nombres'),
                    const SizedBox(height: 15),
                    _buildWhiteInput(lC, 'Apellidos'),
                    const SizedBox(height: 15),
                    _buildWhiteInput(eC, 'Correo electrónico'),
                    const SizedBox(height: 15),
                    _buildWhiteInput(phC, 'Teléfono'),
                    const SizedBox(height: 15),
                    _buildWhiteInput(uC, 'Usuario'),
                    const SizedBox(height: 15),
                    _buildWhiteInput(pC, 'Contraseña', isPassword: true),
                    
                    const SizedBox(height: 25),
                    
                    // Mensaje de error
                    if (vm.error != null)
                      Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.amber),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Botón de registro
                    vm.loading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF5E151D),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final user = User(
                                  id: '',
                                  firstName: fC.text.trim(),
                                  lastName: lC.text.trim(),
                                  email: eC.text.trim(),
                                  phoneNumber: phC.text.trim(),
                                  username: uC.text.trim(),
                                  password: pC.text.trim(),
                                );
                                ref.read(authViewModelProvider).register(context, user);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E151D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Crear cuenta',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    
                    const SizedBox(height: 20),
                    
                    // Enlace para volver a login
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '¿Ya tienes una cuenta? Inicia sesión',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteInput(TextEditingController controller, String labelText, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}