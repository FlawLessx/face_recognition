// ignore_for_file: use_build_context_synchronously
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:face_recognition_mobile/cubit/face_cubit.dart';
import 'package:face_recognition_mobile/pages/result_page.dart';
import 'package:face_recognition_mobile/util/face_painter.dart';
import 'package:face_recognition_mobile/widget/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_editor/image_editor.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key, required this.isAdd, this.name})
      : super(key: key);
  // To distinguish whether the process is adding or detecting
  final bool isAdd;
  // If process is adding will have name from dialog before navigating to this page
  final String? name;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? controller;
  List<CameraDescription>? _cameras;
  int cameraIndex = 0;
  String? cameraException;

  File? cameraFile;
  bool takingPicture = false;

  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  late FaceDetector faceDetector;
  CustomPaint? _customPaint;
  int counter = 0;
  bool _isBusy = false;

  List<double> processedFrame = [];
  bool imageCanSend = false;

  @override
  void initState() {
    _initCamera();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController != null && !cameraController.value.isInitialized) {
      return;
    }

    // Disposing camera stream for release unused memory
    // And avoiding memory leak
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController!.description);
    }
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  // Camera Function
  Future<void> _initCamera() async {
    // Initialize face detector options
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableContours: true,
      ),
    );

    // Check for available cameras
    try {
      _cameras = await availableCameras();
    } catch (e) {
      if (e is CameraException) {
        cameraExceptionParser(e);
      } else {
        cameraException = "Can't initialize camera";
      }
      showSnackbar(context, cameraException!, false);
    }

    // If multiple cameras available, e.g back and front
    // Then will be forced to use front camera
    try {
      CameraDescription? cameraDescription;

      for (var i = 0; i < _cameras!.length; i++) {
        final element = _cameras![i];

        if (element.lensDirection == CameraLensDirection.front) {
          cameraDescription = element;
          cameraIndex = i;
          setState(() {});
          break;
        }
      }

      // Otherwise will be use defaul camera
      if (cameraDescription == null && _cameras!.isNotEmpty) {
        cameraDescription = _cameras!.first;
      }

      // Assign camera controller with max resolution and audio false
      controller = CameraController(cameraDescription!, ResolutionPreset.max,
          enableAudio: false);
      controller!.initialize().then((_) {
        if (!mounted) {
          return;
        }
        // Assign default zoom level
        controller?.getMinZoomLevel().then((value) {
          zoomLevel = value;
          minZoomLevel = value;
        });
        controller?.getMaxZoomLevel().then((value) {
          maxZoomLevel = value;
        });
        controller?.startImageStream(_processCameraImage);
        setState(() {});
      }).catchError((Object e) {
        if (e is CameraException) {
          cameraExceptionParser(e);
        } else {
          cameraException = "Can't initialize camera";
        }
        showSnackbar(context, cameraException!, false);
      });
    } catch (e) {
      if (e is CameraException) {
        cameraExceptionParser(e);
      } else {
        cameraException = "Can't initialize camera";
      }
      showSnackbar(context, cameraException!, false);
    }
  }

  // Stop camera stream then disposing camera and face detector
  // For better memory management
  Future _stopCamera() async {
    if (controller != null && controller!.value.isStreamingImages) {
      await controller!.stopImageStream();
    }

    if (cameraFile != null) {
      await cameraFile!.delete();
    }

    await controller?.dispose();
    await faceDetector.close();
    controller = null;
  }

  // Re-Assign previous camera controller if app inactive then active again
  void onNewCameraSelected(CameraDescription cameraDescription) {
    controller = CameraController(cameraDescription, ResolutionPreset.max,
        enableAudio: false);
    controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        cameraExceptionParser(e);
      } else {
        cameraException = "Can't initialize camera";
      }

      showSnackbar(context, cameraException!, false);
    });
    setState(() {});
  }

  // Parsing camera package error to be readable by user
  void cameraExceptionParser(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        cameraException = 'User denied camera access.';
        break;
      default:
        cameraException = "Can't initialize camera";
        break;
    }
  }

  // Converting camera into an image file
  Future<void> takePicture() async {
    if (controller != null) {
      try {
        takingPicture = true;
        setState(() {});

        // Stop current camera stream
        if (controller!.value.isStreamingImages) {
          await controller!.stopImageStream();
        }

        // Taking picture
        final xfile = await controller!.takePicture();

        // There's a bug with camera package that's the resuul of and front camera image will be flipped
        // To fix this, will use image_editor package to flip to original one like at camera stream
        if (_cameras![cameraIndex].lensDirection == CameraLensDirection.front) {
          // 1. read the image from disk into memory
          final tempFile = File(xfile.path);
          Uint8List? imageBytes = await tempFile.readAsBytes();

          // 2. flip the image on the X axis
          final ImageEditorOption option = ImageEditorOption();
          option.addOption(const FlipOption(horizontal: true));
          imageBytes = await ImageEditor.editImage(
              image: imageBytes, imageEditorOption: option);

          // 3. write the image back to disk
          if (imageBytes != null) {
            await tempFile.delete();
            await tempFile.writeAsBytes(imageBytes);
            cameraFile = tempFile;
          } else {
            cameraFile = File(xfile.path);
          }
        } else {
          cameraFile = File(xfile.path);
        }

        if (widget.isAdd) {
          BlocProvider.of<FaceCubit>(context)
              .addFace(widget.name!, cameraFile!);
        } else {
          BlocProvider.of<FaceCubit>(context).detectFace(cameraFile!);
        }

        takingPicture = false;
        setState(() {});
        log('Take Picture');
      } catch (e) {
        log('Camera Exception: $e');
      }
    }
  }

  // If response from backend not success, will delete the cameraFile then re-stream camera
  Future<void> clearCameraFile() async {
    if (cameraFile != null) {
      await cameraFile!.delete();
    }

    cameraFile = null;
    processedFrame.clear();
    imageCanSend = false;
    setState(() {});

    if (controller != null && controller!.value.isStreamingImages) {
      await controller?.stopImageStream();
    }

    await controller?.startImageStream(_processCameraImage);
  }

  // Processing face detection on camera stream, will be processed every 5 frame
  // And is not busy taking picture or uploading file to backend
  // For better memory management
  Future _processCameraImage(CameraImage image) async {
    if (counter % 5 == 0) {
      if (_isBusy) return;
      _isBusy = true;
      setState(() {});

      // Write buffer from image plane
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Assign image size from original camera width and height
      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      // Check camera orientation
      final camera = _cameras![cameraIndex];
      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation);
      if (imageRotation == null) return;

      // Check image format
      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) return;

      // Converted camera resolution into 720p, with supported platform
      // Android: 720 x 480
      // iOS: 640: 480
      final planeData = image.planes.map(
        (Plane plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: Platform.isAndroid ? 720 : 640,
            width: 480,
          );
        },
      ).toList();

      // Input image data to be processed by MLKit
      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      final inputImage =
          InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

      final List<Face> faces = await faceDetector.processImage(inputImage);

      // Painting face
      if (faces.isNotEmpty) {
        final painter = FaceDetectorPainter(
            faces.first,
            inputImage.inputImageData!.size,
            inputImage.inputImageData!.imageRotation);
        _customPaint = CustomPaint(painter: painter);
      } else {
        _customPaint = null;
      }

      for (Face face in faces) {
        // If total processed frame more than 10, then
        // Current image can be send to backend
        // This is for avoiding face already processed after then page open
        if (processedFrame.length > 10) {
          imageCanSend = true;
          processedFrame.clear();
        } else {
          processedFrame.add(0);
        }

        // If landmark was enabled with FaceDetectorOptions:
        final FaceLandmark? nose = face.landmarks[FaceLandmarkType.noseBase];
        final FaceLandmark? leftEye = face.landmarks[FaceLandmarkType.leftEye];
        final FaceLandmark? rightEye =
            face.landmarks[FaceLandmarkType.rightEye];
        // Will process if face straight to the camera
        // With recognized left eye & right eye & nose
        // You can add more face landmark for validating if face straight to the camera
        if (leftEye != null && rightEye != null && nose != null) {
          final math.Point<int> leftEyePos = leftEye.position;
          final math.Point<int> rightEyePos = rightEye.position;
          final math.Point<int> nosePos = nose.position;

          log('Position: Left(${leftEyePos.x}) Right(${rightEyePos.x}) Nose(${nosePos.x})');
          // If already taking picture will ignore
          if (!takingPicture && imageCanSend) {
            await takePicture();
          }
        }

        // If all process done then update current process not busy
        _isBusy = false;
        if (mounted) {
          setState(() {});
        }
      }
    }

    // Counting frame
    // Don't let counter go out of control forever
    if (counter == 1000) {
      counter = 0;
    } else {
      counter++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FaceCubit, FaceState>(
      listener: (context, state) async {
        if (state is FaceError) {
          // Re-init camera stream
          await clearCameraFile();
          showSnackbar(context, state.message, false);
        } else if (state is AddFaceSuccess) {
          showSnackbar(context, 'Face added successfully', true);
          await Future.delayed(const Duration(seconds: 3));
          // Navigating back to home page
          Navigator.pop(context);
        } else if (state is DetectFaceSuccess) {
          // Re-init camera stream
          await clearCameraFile();
          // Then disposing
          await _stopCamera();
          // Navigate to result page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(data: state.data),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 30,
            ),
          ),
          title: const Text(
            'Camera Page',
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: cameraView(),
        ),
      ),
    );
  }

  Widget cameraView() {
    final size = MediaQuery.of(context).size;
    // calculate scale depending on screen and camera ratios
    // this is actually size.aspectRatio / (1 / camera.aspectRatio)
    // because camera preview size is received as landscape
    // but we're calculating for portrait orientation
    var scale = size.aspectRatio *
        (controller != null && controller!.value.isInitialized
            ? controller!.value.aspectRatio
            : 0);

    // to prevent scaling down, invert the value
    if (scale < 1) scale = 1 / scale;

    // Showing camera file when not null
    // Indicating the face still processed at backend
    return cameraFile != null
        ? Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Transform.scale(
                  scale: scale,
                  child: Image.file(
                    cameraFile!,
                    width: double.maxFinite,
                    height: double.maxFinite,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        : controller == null || !controller!.value.isInitialized
            ? const SizedBox()
            : Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Center(child: CameraPreview(controller!)),
                  ),
                  if (_customPaint != null)
                    Transform.scale(scale: scale, child: _customPaint!),
                ],
              );
  }
}
