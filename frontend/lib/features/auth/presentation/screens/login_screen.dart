import 'package:flutter/material.dart';
import 'package:planit_app/features/auth/data/services/auth_service.dart';

class LoginScreen  extends StatefulWidget{
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
    void dispose(){
     _emailController.dispose();
     _passwordController.dispose();
     super.dispose();
  }

  Future<void> _handleLogin() async{
    if(_formKey.currentState!.validate()){
      setState(() => _isLoading = true);
      try{
        final token = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if(token != null && mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Inicio de sesion exitoso!')),
          );
        }
      }catch (e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'))
          );
        }
      }finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlanIt - Iniciar Sesión'),
        centerTitle: true,
      ),
      body: Padding(
          padding: EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Bienvenido de nuevo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electronico',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if(value == null || value.isEmpty){
                            return 'Por favor introduce tu correo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value){
                          if(value == null || value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                                :const Text(
                                    'Iniciar Sesión',
                                      style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      )
    );
  }
}