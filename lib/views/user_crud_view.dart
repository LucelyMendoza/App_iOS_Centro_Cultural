// lib/views/user_crud_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_viewmodel.dart';
import '../models/user.dart';

/// -------------------------------------------------
/// 1. Lista de Usuarios
/// -------------------------------------------------
class UserListView extends StatelessWidget {
  const UserListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserViewModel()..loadUsers(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Usuarios')),
        body: Consumer<UserViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.users.isEmpty) {
              return const Center(child: Text('No hay usuarios aún.'));
            }
            return ListView.builder(
              itemCount: vm.users.length,
              itemBuilder: (context, i) {
                final u = vm.users[i];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${u.firstName} ${u.lastName}'),
                  subtitle: Text(u.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: Provider.of<UserViewModel>(
                                context,
                                listen: false,
                              ),
                              child: const UserFormView(),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => vm.deleteUser(u.id),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: Consumer<UserViewModel>(
          builder: (context, vm, _) => FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: vm,
                    child: const UserFormView(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------------------
/// 2. Formulario de Usuario (Crear / Editar)
/// -------------------------------------------------
class UserFormView extends StatefulWidget {
  final User? user;
  const UserFormView({Key? key, this.user}) : super(key: key);

  @override
  _UserFormViewState createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: widget.user?.lastName ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _usernameCtrl = TextEditingController(text: widget.user?.username ?? '');
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserViewModel>(context, listen: false);
    final isEditing = widget.user != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Usuario' : 'Crear Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre y apellido
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (v ?? '').contains('@') ? null : 'Invalid email',
              ),
              const SizedBox(height: 12),

              // Teléfono
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              // Username
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Solo en creación: password y confirmación
              if (!isEditing) ...[
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => (v ?? '').length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Passwords must match' : null,
                ),
                const SizedBox(height: 12),
              ],

              // Botón Crear/Actualizar
              ElevatedButton(
                child: Text(isEditing ? 'Update' : 'Create'),
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  final user = User(
                    id: widget.user?.id ?? '',
                    firstName: _firstNameCtrl.text.trim(),
                    lastName: _lastNameCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    phoneNumber: _phoneCtrl.text.trim(),
                    username: _usernameCtrl.text.trim(),
                    password: isEditing ? null : _passwordCtrl.text,
                  );

                  if (isEditing) {
                    vm.updateUser(user);
                  } else {
                    vm.createUser(user);
                  }

                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
