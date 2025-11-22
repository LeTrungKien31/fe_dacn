import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _St();
}

class _St extends ConsumerState<RegisterScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext ctx, WidgetRef ref) async {
    final e = email.text.trim();
    final p = pass.text;
    final n = name.text.trim();
    if (e.isEmpty || p.isEmpty || n.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ họ tên, email, mật khẩu'),
        ),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .register(fullname: n, email: e, password: p);
      await ref.read(authServiceProvider).login(email: e, password: p);
      if (ctx.mounted) {
        // sang dashboard và thay thế màn hình register
        Navigator.of(ctx).pushReplacementNamed('/dashboard');
      }
    } catch (err) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $err')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Họ tên'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : () => _submit(ctx, ref),
                    child: Text(loading ? 'Đang tạo...' : 'Tạo tài khoản'),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(ctx).pushReplacementNamed('/login'),
                  child: const Text('Đã có tài khoản? Đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
