import 'package:flutter/material.dart';
import '../helpers.dart';

class LockScreen extends StatefulWidget {
  final String pin;
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.pin, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final ctrl = TextEditingController();
  bool err = false;

  void submit() {
    if (ctrl.text == widget.pin) {
      widget.onUnlock();
    } else {
      setState(() => err = true);
      ctrl.clear();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => err = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: goldColor, borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.lock, color: Colors.black87, size: 26),
            ),
            const SizedBox(height: 18),
            const Text('Enter PIN', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 26),
            SizedBox(
              width: 160,
              child: TextField(
                controller: ctrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: err ? expenseColor : Colors.white24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: goldColor),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onSubmitted: (_) => submit(),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: submit,
              style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black87),
              child: const Text('Unlock'),
            ),
            if (err)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Incorrect PIN', style: TextStyle(color: expenseColor)),
              ),
          ],
        ),
      ),
    );
  }
}
