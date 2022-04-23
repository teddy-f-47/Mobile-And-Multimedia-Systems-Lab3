# flutter_google_ml_kit

This repository contains the work for Lab3.

The application is developed with ***Flutter***.

## The built Android app

APK File (141.7 MB) : https://drive.google.com/file/d/1yCBmAGNMoVjyeC0uPUCuOEgVNd9-RZmB/view?usp=sharing

The APK file is too large to be uploaded in a commit to Github, hence it is made available via Google Drive.

## Screenshots

![Alt text](/dev_screenshot/1_initial_page.jpg?raw=true "Initial State")
![Alt text](/dev_screenshot/2_camera_view.jpg?raw=true "Take Photo with Camera")
![Alt text](/dev_screenshot/3_testa.jpg?raw=true "Test 1")
![Alt text](/dev_screenshot/4_testb.jpg?raw=true "Test 2")
![Alt text](/dev_screenshot/5_testc.jpg?raw=true "Test 3")
![Alt text](/dev_screenshot/6_testd.jpg?raw=true "Test 4")

## The code

All of the code for developing the app is available in the directory lib/.

### main.dart

This is the 'root' of the app that contains code for the home page. Here, there is a button to select an image from Gallery using ImagePicker, and there is another button that navigates to cameraview.dart to take a photo using Camera. Eventually, main.dart calls functions from processing.dart to get the labels, text, and detected object boundaries of a given image.

### cameraview.dart

This is the code for the 'camera' page where the user can take a picture as an input for the app.

### processing.dart

This is the code for image processing with Google ML Kit. There are three functions for image labelling, text recognition, and object detection.

### constants.dart

This file contains constant variables that are re-usable across the app.

### styling.dart

This file contains constants for custom styling, also re-usable across the app.

## Dependencies

Information about dependencies can be found in the file pubspec.yaml.

