import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'cameraview.dart';
import 'constants.dart';
import 'styling.dart';

import 'package:google_ml_kit/google_ml_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Constants.appTitle,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: Constants.appTitle, camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.camera,
  }) : super(key: key);

  final String title;
  final CameraDescription camera;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ImageLabeler imageLabeler = GoogleMlKit.vision.imageLabeler();
  TextDetector textRecognizer = GoogleMlKit.vision.textDetector();
  ObjectDetector objectDetector = GoogleMlKit.vision.objectDetector(
      ObjectDetectorOptions(classifyObjects: true, trackMutipleObjects: true));

  List? _detectedObjects;
  Size? _currentImageAbsSize;
  bool _isBusy = false;
  Image _currentImage = Image.asset('assets/placeholder.jpg');
  String _currentTags = Constants.tagTextDefault;
  String _currentDetectedText = Constants.detectedTextDefault;

  @override
  void initState() {
    super.initState();
  }

  _getFromGallery() async {
    PickedFile? pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      InputImage visionInput = InputImage.fromFile(imageFile);

      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      Size visionInputSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      processImage(visionInput);

      if (mounted) {
        setState(() {
          _currentImage = Image.file(imageFile);
          _currentImageAbsSize = visionInputSize;
        });
      }
    }
  }

  _takePicture() async {
    final String? imagePath = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CameraView(camera: widget.camera)));
    if (imagePath != null) {
      File imageFile = File(imagePath);
      InputImage visionInput = InputImage.fromFile(imageFile);

      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      Size visionInputSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());

      processImage(visionInput);

      if (mounted) {
        setState(() {
          _currentImage = Image.file(imageFile);
          _currentImageAbsSize = visionInputSize;
        });
      }
    }
  }

  Future<void> processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;
    await Future.delayed(Constants.delayShort);

    final List<ImageLabel>? labels =
        await imageLabeler.processImage(inputImage);
    final RecognisedText? texts = await textRecognizer.processImage(inputImage);
    final List<DetectedObject>? objects =
        await objectDetector.processImage(inputImage);

    String output1 = Constants.tagTextError;
    String output2 = Constants.detectedTextError;
    List? output3;
    if (labels != null) {
      output1 = Constants.appSubtitleTag;
      for (ImageLabel label in labels) {
        double confidencePercentage = label.confidence * 100;
        output1 = output1 +
            'Label: ${label.label}, Confidence: ${confidencePercentage.toStringAsFixed(2)}%\n';
      }
    }
    if (texts != null) {
      output2 = Constants.appSubtitleDetectedText;
      for (TextBlock block in texts.blocks) {
        output2 = output2 + block.text + '\n';
      }
    }
    if (objects != null) {
      output3 = List.from(objects);
    }

    _isBusy = false;
    if (mounted) {
      setState(() {
        _currentTags = output1;
        _currentDetectedText = output2;
        _detectedObjects = output3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size stackChildrenSize = Size(MediaQuery.of(context).size.width,
        MediaQuery.of(context).size.height * Styling.imageHeightRelative);
    List<Widget> stackChildren = [];
    stackChildren.add(_currentImage);
    if (_detectedObjects != null &&
        _currentImageAbsSize?.width != null &&
        _currentImageAbsSize?.height != null) {
      double factorX = stackChildrenSize.width / _currentImageAbsSize!.width;
      double factorY = stackChildrenSize.height / _currentImageAbsSize!.height;

      for (DetectedObject anObject in _detectedObjects!) {
        Widget objectBoundary = Container(
          child: Positioned(
            top: anObject.getBoundinBox().top * factorY,
            left: anObject.getBoundinBox().left * factorX,
            width: anObject.getBoundinBox().width * factorX,
            height: anObject.getBoundinBox().height * factorY,
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                color: Colors.green,
                width: Styling.objectBoundaryWidth,
              )),
              child: Text(
                (anObject.getLabels() != null &&
                        anObject.getLabels().isNotEmpty)
                    ? anObject.getLabels().first.getText()
                    : Constants.objectLabelDefault,
                style: const TextStyle(
                  backgroundColor: Colors.green,
                  color: Colors.white,
                  fontSize: Styling.objectBoundaryFontSize,
                ),
              ),
            ),
          ),
        );
        stackChildren.add(objectBoundary);
      }
    }

    return FutureBuilder<void>(
      future: loadingAnim(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // If the Future is complete, display the Scaffold.
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height *
                        Styling.imageHeightRelative,
                    child: Stack(
                      alignment: Alignment.center,
                      children: stackChildren,
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(Styling.verticalGapSmall),
                      child: Text(_currentTags),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(Styling.verticalGapSmall),
                      child: Text(_currentDetectedText),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Styling.buttonHeight),
                      ),
                      onPressed: () {
                        _getFromGallery();
                      },
                      child: const Text(Constants.btnLabelSelectImage),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(Styling.buttonHeight),
                      ),
                      onPressed: () {
                        _takePicture();
                      },
                      child: const Text(Constants.btnLabelShootImage),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Otherwise, display a loading indicator.
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
          //const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future loadingAnim() {
    return Future.delayed(const Duration(milliseconds: 1200));
  }
}
