import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../helpers.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  bool isSignup = false;
  bool loading = false;
  String? error;

  Future<void> submit() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      setState(() => error = 'Please enter both email and password');
      return;
    }
    if (isSignup && (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty || dobCtrl.text.trim().isEmpty)) {
      setState(() => error = 'Please also enter your name, phone number and date of birth');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (isSignup) {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        await cred.user?.updateDisplayName(nameCtrl.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'profile': {
            'name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
            'dob': dobCtrl.text.trim(),
            'email': email,
          },
        }, SetOptions(merge: true));
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Something went wrong';
      if (e.code == 'user-not-found') msg = 'This email is not registered. Please sign up.';
      if (e.code == 'wrong-password') msg = 'Incorrect password.';
      if (e.code == 'email-already-in-use') msg = 'This email is already registered. Please log in.';
      if (e.code == 'weak-password') msg = 'Password must be at least 6 characters.';
      if (e.code == 'invalid-email') msg = 'Please enter a valid email address.';
      setState(() => error = msg);
    } catch (e) {
      setState(() => error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, -1.0),
            radius: 1.6,
            colors: [heroDark2, bgDark],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF0CE85), goldDeep]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: goldColor.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  isSignup ? 'Create New Account' : 'Log In',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isSignup
                      ? 'Register on $appName to keep your data synced forever.'
                      : 'Log in to sync your data across any device.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
                const SizedBox(height: 28),
                if (isSignup) ...[
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration('Full Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dobCtrl,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration('Date of Birth').copyWith(
                      suffixIcon: const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000, 1, 1),
                        firstDate: DateTime(1930),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => dobCtrl.text = DateFormat('dd MMM yyyy').format(picked));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: fieldDecoration('Phone Number'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: fieldDecoration('Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: fieldDecoration('Password'),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!, style: const TextStyle(color: expenseColor, fontSize: 13)),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldColor,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loading ? 'Please wait...' : (isSignup ? 'Sign Up' : 'Login')),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => setState(() => isSignup = !isSignup),
                  child: Text(
                    isSignup ? 'Already have an account? Log in' : 'New user? Sign up',
                    style: const TextStyle(color: goldColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
