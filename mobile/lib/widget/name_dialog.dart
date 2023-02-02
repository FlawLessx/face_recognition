import 'package:face_recognition_mobile/pages/camera_page.dart';
import 'package:flutter/material.dart';

class NameDialog extends StatefulWidget {
  const NameDialog({super.key});

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final textController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('User Name'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: textController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validating if name empty or not
            // If valid then route to next page
            if (formKey.currentState!.validate()) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CameraPage(
                    isAdd: true,
                    name: textController.text,
                  ),
                ),
              );
            }
          },
          child: const Text('Continue'),
        )
      ],
    );
  }
}
