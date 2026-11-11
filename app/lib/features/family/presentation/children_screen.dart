import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/drawer_page_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/entities/child.dart';
import 'providers/children_provider.dart';

class ChildrenScreen extends ConsumerStatefulWidget {
  const ChildrenScreen({super.key});

  @override
  ConsumerState<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends ConsumerState<ChildrenScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(childrenControllerProvider).loadChildren(),
    );
  }

  Future<void> _showAddChild() async {
    final values = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => const _AddChildSheet(),
    );

    if (values == null || !mounted) return;
    final added = await ref
        .read(childrenControllerProvider)
        .addChild(name: values.$1, school: values.$2);
    if (!mounted || added) return;
    _showError(ref.read(childrenControllerProvider).errorMessage);
  }

  Future<void> _showChangeSchool(Child child) async {
    final school = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => _ChangeSchoolSheet(child: child),
    );

    if (school == null || !mounted || school == child.schoolName) return;
    final updated = await ref
        .read(childrenControllerProvider)
        .changeSchool(childId: child.id, school: school);
    if (!mounted) return;
    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School updated and sent for approval.')),
      );
      return;
    }
    _showError(ref.read(childrenControllerProvider).errorMessage);
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Unable to update children.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(childrenControllerProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: DrawerPageAppBar(
        title: 'Manage children',
        backgroundColor: AppTheme.background,
        actions: [
          IconButton(
            tooltip: 'Add child',
            onPressed: controller.isSubmitting ? null : _showAddChild,
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadChildren,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Text('Your family', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Manage the children connected to your school transport.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 22),
            if (controller.isLoading && controller.children.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null &&
                controller.children.isEmpty)
              _ErrorState(
                message: controller.errorMessage!,
                onRetry: controller.loadChildren,
              )
            else if (controller.children.isEmpty)
              _EmptyChildren(onAdd: _showAddChild)
            else ...[
              ...controller.children.map(
                (child) => _ChildCard(
                  child: child,
                  onChangeSchool: controller.isSubmitting
                      ? null
                      : () => _showChangeSchool(child),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: controller.isSubmitting ? null : _showAddChild,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add another child'),
              ),
            ],
            if (controller.isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a child', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Connect a child to your school transport account.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Child name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the child name'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _schoolController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'School'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the school name'
                : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop((
                    _nameController.text.trim(),
                    _schoolController.text.trim(),
                  ));
                }
              },
              child: const Text('Add child'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChangeSchoolSheet extends StatefulWidget {
  const _ChangeSchoolSheet({required this.child});

  final Child child;

  @override
  State<_ChangeSchoolSheet> createState() => _ChangeSchoolSheetState();
}

class _ChangeSchoolSheetState extends State<_ChangeSchoolSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _schoolController = TextEditingController(
    text: widget.child.schoolName,
  );

  @override
  void dispose() {
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      24,
      24,
      24,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change school', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Update the school for ${widget.child.fullName}.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _schoolController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'School'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter the school name'
                : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop(_schoolController.text.trim());
                }
              },
              child: const Text('Save school'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child, required this.onChangeSchool});

  final Child child;
  final VoidCallback? onChangeSchool;

  @override
  Widget build(BuildContext context) {
    final initials = child.firstName.isEmpty
        ? '?'
        : '${child.firstName[0]}${child.lastName.isEmpty ? '' : child.lastName[0]}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.blueTint,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      child.schoolName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (child.grade != null && child.grade!.isNotEmpty)
                      Text(
                        child.grade!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onChangeSchool,
              icon: const Icon(Icons.school_outlined),
              label: const Text('Change school'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChildren extends StatelessWidget {
  const _EmptyChildren({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 72),
    child: Column(
      children: [
        const Icon(
          Icons.people_outline_rounded,
          color: AppTheme.blue,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'No children added yet',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Add a child to start managing school transport access.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Add child'),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFE58A24), size: 44),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}
