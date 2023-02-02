import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'coordinates_translator.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.face, this.absoluteImageSize, this.rotation);

  final Face face;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint facePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.blue;

    void paintContour(FaceContourType type) {
      final faceContour = face.contours[type];
      if (faceContour?.points != null) {
        for (var i = 0; i < faceContour!.points.length; i++) {
          final point = faceContour.points[i];

          final startOffset = Offset(
            translateX(point.x.toDouble(), rotation, size, absoluteImageSize),
            translateY(point.y.toDouble(), rotation, size, absoluteImageSize),
          );

          canvas.drawCircle(startOffset, 1, facePaint);

          canvas.drawLine(
            startOffset,
            i < faceContour.points.length - 1
                ? Offset(
                    translateX(faceContour.points[i + 1].x.toDouble(), rotation,
                        size, absoluteImageSize),
                    translateY(faceContour.points[i + 1].y.toDouble(), rotation,
                        size, absoluteImageSize),
                  )
                : type == FaceContourType.face
                    ? Offset(
                        translateX(faceContour.points[0].x.toDouble(), rotation,
                            size, absoluteImageSize),
                        translateY(faceContour.points[0].y.toDouble(), rotation,
                            size, absoluteImageSize),
                      )
                    : startOffset,
            facePaint,
          );
        }
      }
    }

    paintContour(FaceContourType.face);
    paintContour(FaceContourType.leftEyebrowTop);
    paintContour(FaceContourType.leftEyebrowBottom);
    paintContour(FaceContourType.rightEyebrowTop);
    paintContour(FaceContourType.rightEyebrowBottom);
    paintContour(FaceContourType.leftEye);
    paintContour(FaceContourType.rightEye);
    paintContour(FaceContourType.upperLipTop);
    paintContour(FaceContourType.upperLipBottom);
    paintContour(FaceContourType.lowerLipTop);
    paintContour(FaceContourType.lowerLipBottom);
    paintContour(FaceContourType.noseBridge);
    paintContour(FaceContourType.noseBottom);
    paintContour(FaceContourType.leftCheek);
    paintContour(FaceContourType.rightCheek);
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.face != face;
  }
}
