import 'package:flutter/material.dart';

import '../../auth/presentation/verification_screen.dart';
import '../domain/entities/child.dart';

class ChildSetupScreen extends StatefulWidget {
  const ChildSetupScreen({super.key});

  @override
  State<ChildSetupScreen> createState() => _ChildSetupScreenState();
}

class _ChildSetupScreenState extends State<ChildSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _schoolController = TextEditingController();
  final List<Child> _children = [];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  bool _addChild() {
    if (!_formKey.currentState!.validate()) return false;

    final fullName = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final school = _schoolController.text.trim();
    final names = fullName.split(RegExp(r'\s+'));
    final firstName = names.firstOrNull ?? fullName;
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'Student';

    setState(() {
      _children.add(
        Child(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: firstName,
          lastName: lastName,
          age: age,
          schoolName: school,
        ),
      );
      _nameController.clear();
      _ageController.clear();
      _schoolController.clear();
    });
    return true;
  }

  void _continue() {
    final hasUnfinishedChild =
        _nameController.text.trim().isNotEmpty ||
        _ageController.text.trim().isNotEmpty ||
        _schoolController.text.trim().isNotEmpty;
    if (hasUnfinishedChild) {
      if (!_addChild()) return;
    } else if (_children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one child profile first.')),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            VerificationScreen(children: List.unmodifiable(_children)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family setup'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          children: [
            Text(
              'Add your child',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'We use this to connect you to the right school bus route.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            const Text(
              'Child full name',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your child\'s name'
                  : null,
              decoration: const InputDecoration(hintText: 'Maya Morgan'),
            ),
            const SizedBox(height: 18),
            const Text('Age', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final age = int.tryParse(value?.trim() ?? '');
                if (age == null || age < 3 || age > 18) {
                  return 'Enter an age from 3 to 18';
                }
                return null;
              },
              decoration: const InputDecoration(hintText: '10'),
            ),
            const SizedBox(height: 18),
            const Text(
              'School name',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _schoolController,
              textInputAction: TextInputAction.done,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter the school name'
                  : null,
              decoration: const InputDecoration(hintText: 'Oakwood Elementary'),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _addChild(),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _children.isEmpty ? 'Add child' : 'Add another child',
              ),
            ),
            if (_children.isNotEmpty) ...[
              const SizedBox(height: 22),
              Text(
                'Children added',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._children.map(
                (child) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5ECFF)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFEAF2FF),
                        child: Text(
                          child.firstName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF1769E0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${child.age} years old · ${child.schoolName}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1769E0),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _continue,
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
