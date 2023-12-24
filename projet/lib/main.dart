import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(firstCamera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription firstCamera;
  const MyApp({required this.firstCamera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Camera Demo', camera: firstCamera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final CameraDescription camera;

  MyHomePage({Key? key, required this.title, required this.camera})
      : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _controller;
  late FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _faceDetector = GoogleMlKit.vision.faceDetector();

    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller.startImageStream((CameraImage image) {
        _processImage(image);
      });
    });
  }

  void _processImage(CameraImage image) async {
    try {
      final inputImage = InputImage.fromBytes(
  bytes: _concatenatePlanes(image.planes),
  metadata: InputImageMetadata(
    size: Size(image.width.toDouble(), image.height.toDouble()),
    rotation: InputImageRotation.rotation0deg,
    format:  InputImageFormat.nv21,
    bytesPerRow: image.planes[0].bytesPerRow, // Replace with the appropriate plane
  ),
);


      final List<Face> faces = await _faceDetector.processImage(inputImage);

      // Process the detected faces (you can do something with the faces here)
      for (Face face in faces) {
        print("Face detected at: ${face.boundingBox}");
      }
    } catch (e) {
      print(e);
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    planes.forEach((plane) {
      allBytes.putUint8List(plane.bytes);
    });
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: CameraPreview(_controller),
      ),
    );
  }
}
