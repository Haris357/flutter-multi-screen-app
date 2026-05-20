import 'package:flutter/material.dart';

import '../controllers/course_scope.dart';
import '../models/course_model.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Form used to both create a new course and edit an existing one.
///
/// Pass [existing] to enter edit mode — the form pre-fills its fields with
/// the course's data and the submit button triggers an update instead of a
/// create.
class CourseFormScreen extends StatefulWidget {
  const CourseFormScreen({super.key, this.existing});

  final CourseModel? existing;

  bool get isEditing => existing != null;

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    if (value.trim().length < 3) {
      return '$fieldName must be at least 3 characters.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final controller = CourseScope.of(context);
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    final error = widget.isEditing
        ? await controller.updateCourse(
            widget.existing!.copyWith(
              title: title,
              description: description,
            ),
          )
        : await controller.addCourse(
            title: title,
            description: description,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit course' : 'Add course';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _titleController,
                  label: 'Title',
                  prefixIcon: Icons.title,
                  textInputAction: TextInputAction.next,
                  validator: (v) => _validateRequired(v, 'Title'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  minLines: 4,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) => _validateRequired(v, 'Description'),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: widget.isEditing ? 'Save changes' : 'Create course',
                  onPressed: _submit,
                  isLoading: _submitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
