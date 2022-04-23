import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'constants.dart';
import 'styling.dart';

class Processor {
  ImageLabeler? imageLabeler;
  TextDetector? textRecognizer;
  ObjectDetector? objectDetector;
  File? currentImageFile;
  InputImage? currentImage;
  bool _isBusy = false;

  Processor(File imageFile) {
    imageLabeler = GoogleMlKit.vision.imageLabeler();
    textRecognizer = GoogleMlKit.vision.textDetector();
    objectDetector = GoogleMlKit.vision.objectDetector(ObjectDetectorOptions(
        classifyObjects: true, trackMutipleObjects: true));
    currentImageFile = imageFile;
    currentImage = InputImage.fromFile(imageFile);
  }

  Future<String> getImageLabels() async {
    while (_isBusy) {
      await Future.delayed(Constants.delayShort);
    }

    _isBusy = true;
    String output = Constants.tagTextError;

    if (imageLabeler == null || currentImage == null) {
      _isBusy = false;
      return output;
    } else {
      final List<ImageLabel>? labels =
          await imageLabeler!.processImage(currentImage!);
      if (labels != null) {
        output = Constants.appSubtitleTag;
        for (ImageLabel label in labels) {
          double confidencePercentage = label.confidence * 100;
          output = output +
              'Label: ${label.label}, Confidence: ${confidencePercentage.toStringAsFixed(2)}%\n';
        }
      }
      _isBusy = false;
      return output;
    }
  }

  Future<String> getRecognisedTexts() async {
    while (_isBusy) {
      await Future.delayed(Constants.delayShort);
    }

    _isBusy = true;
    String output = Constants.detectedTextError;

    if (textRecognizer == null || currentImage == null) {
      _isBusy = false;
      return output;
    } else {
      final RecognisedText? texts =
          await textRecognizer!.processImage(currentImage!);
      if (texts != null) {
        output = Constants.appSubtitleDetectedText;
        for (TextBlock block in texts.blocks) {
          output = output + block.text + '\n';
        }
      }
      _isBusy = false;
      return output;
    }
  }

  Future<List<Widget>> getDetectedObjects(
      File imageFile, Size layoutSize) async {
    while (_isBusy) {
      await Future.delayed(Constants.delayShort);
    }

    _isBusy = true;
    List<Widget> output = [Image.file(imageFile)];

    if (objectDetector == null || currentImage == null) {
      _isBusy = false;
      return output;
    } else {
      var decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
      Size decodedImageSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      double factorX = layoutSize.width / decodedImageSize.width;
      double factorY = layoutSize.height / decodedImageSize.height;
      final List<DetectedObject>? objects =
          await objectDetector!.processImage(currentImage!);
      if (objects != null) {
        for (DetectedObject anObject in objects) {
          Widget objectBoundary = Container(
            child: Positioned(
              top: anObject.getBoundinBox().top * factorY,
              left: anObject.getBoundinBox().left * factorX,
              height: anObject.getBoundinBox().height * factorY,
              width: anObject.getBoundinBox().width * factorX,
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                  color: Colors.green,
                  width: Styling.objectBoundaryWidth,
                )),
                child: Text(
                  (anObject.getLabels().isNotEmpty)
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
          output.add(objectBoundary);
        }
      }
      _isBusy = false;
      return output;
    }
  }
}
