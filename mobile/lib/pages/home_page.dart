import 'package:face_recognition_mobile/pages/camera_page.dart';
import 'package:face_recognition_mobile/widget/name_dialog.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Center(
            child: SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                      context: context, builder: (_) => const NameDialog());
                },
                child: const Text('Add'),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 100,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraPage(
                        isAdd: false,
                      ),
                    ),
                  );
                },
                child: const Text('Detect'),
              ),
            ),
          )
        ],
      ),
    );
  }
}
