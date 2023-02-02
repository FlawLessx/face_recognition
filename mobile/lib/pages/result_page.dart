import 'package:face_recognition_mobile/model/detect_response.dart';
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.data});
  final DetectResponse data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
      ),
      body: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Name: ${data.name}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Age: ${data.age}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Gender: ${data.gender}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
