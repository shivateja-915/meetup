import 'package:flutter/material.dart';
import '../main.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?['full_name'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await SupabaseService.updateProfile(
        userId: SupabaseService.currentUser!.id,
        fullName: _nameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.profile?['full_name'] ?? 'U';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.warmGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider, width: 0.5)),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                    const Spacer(),
                    Text('Edit Profile', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                          child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Display Name', prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textTertiary)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: SupabaseService.currentUser?.email ?? '',
                          readOnly: true,
                          decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.textTertiary)),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity, height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
