import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:async';
import 'cameraview.dart';
import 'processor.dart';
import 'constants.dart';
import 'styling.dart';

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
  String _currentTags = Constants.tagTextDefault;
  String _currentDetectedText = Constants.detectedTextDefault;
  List<Widget> _detectedObjects = [Image.asset('assets/placeholder.jpg')];

  @override
  void initState() {
    super.initState();
  }

  _getFromGallery() async {
    PickedFile? pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      Size stackChildrenSize = Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height * Styling.imageHeightRelative);

      Processor imageProcessor = Processor(imageFile);
      String newTags = await imageProcessor.getImageLabels();
      String newTexts = await imageProcessor.getRecognisedTexts();
      List<Widget> newObjects =
          await imageProcessor.getDetectedObjects(imageFile, stackChildrenSize);

      if (mounted) {
        setState(() {
          _currentTags = newTags;
          _currentDetectedText = newTexts;
          _detectedObjects = newObjects;
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
      Size stackChildrenSize = Size(MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height * Styling.imageHeightRelative);

      Processor imageProcessor = Processor(imageFile);
      String newTags = await imageProcessor.getImageLabels();
      String newTexts = await imageProcessor.getRecognisedTexts();
      List<Widget> newObjects =
          await imageProcessor.getDetectedObjects(imageFile, stackChildrenSize);

      if (mounted) {
        setState(() {
          _currentTags = newTags;
          _currentDetectedText = newTexts;
          _detectedObjects = newObjects;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = [];
    stackChildren.addAll(_detectedObjects);

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
        }
      },
    );
  }

  Future loadingAnim() {
    return Future.delayed(Constants.delayMedium);
  }
}
