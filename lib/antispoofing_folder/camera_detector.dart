// // Google ML Vision Face Detection and recognition app
// // Use of this source code is governed by a BSD-style license that can be
// // found in the LICENSE file.
// // TO-DO: Add Anti-spoofing to detect not human face in face recognition

// import 'dart:convert';
// import 'dart:io';
// import 'dart:ui';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/rendering.dart';
// import 'package:quiver/collection.dart';
// import 'package:image/image.dart' as imglib;
// import 'package:camera/camera.dart';
// import 'package:google_ml_vision/google_ml_vision.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

// import 'detector_painters.dart';
// import 'detector_utils.dart';
// import 'anti_spoofing.dart';

// enum Choice {
//   view,
//   delete,
//   landmarkFace,
//   normalFace,
//   antiSpoofing,
//   removeSpoofing
// }

// bool _landMarkFace = false;

// class CameraDetector extends StatefulWidget {
//   const CameraDetector({Key? key}) : super(key: key);

//   @override
//   State<StatefulWidget> createState() => _CameraDetectorState();
// }

// class _CameraDetectorState extends State<CameraDetector>
//     with WidgetsBindingObserver {
//   File? jsonFile;
//   dynamic data = {};
//   double threshold = 1.0;
//   Directory? _savedFacesDir;
//   List? _predictedData;
//   tfl.Interpreter? interpreter;
//   final TextEditingController _name = new TextEditingController();
//   dynamic _scanResults;
//   CameraController? _camera;
//   Detector _currentDetector = Detector.face;
//   bool _isDetecting = false;
//   CameraLensDirection _direction = CameraLensDirection.front;
//   bool _faceFound = false;
//   bool _camPos = false; //FALSE means Front Camera and TRUE means Back Camera
//   String _displayBase64FaceImage = "";
//   String _faceName = "Not Recognized";
//   bool _addFaceScreen = false;
//   String? spoofDetectOutput;
//   bool _enableAntiSpoofing = false;

//   final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

//   final FaceDetector _faceDetector =
//       GoogleVision.instance.faceDetector(FaceDetectorOptions(
//     enableLandmarks: true,
//     enableContours: true,
//     enableTracking: true,
//     enableClassification: false,
//     mode: FaceDetectorMode.accurate,
//   ));

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _initializeCamera();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     final CameraController? camController = _camera;
//     if (camController == null || !camController.value.isInitialized) {
//       return;
//     }

//     switch(state) {
//       case AppLifecycleState.resumed:
//         print("App is in resumed");
//         _currentDetector = Detector.face;
//         _initializeCamera();
//         break;
//       case AppLifecycleState.inactive:
//         print("App is in inactive - no need to do anything");
//         break;
//       case AppLifecycleState.paused:
//         print("App is in paused - dispose Camera Controller and ImageStream");
//         if (camController != null) {
//           camController.stopImageStream();
//           camController.dispose();
//         }
//         break;
//       case AppLifecycleState.detached:
//         print("App is in detached");
//         break;
//       case AppLifecycleState.hidden:
//         // TODO: Handle this case.
//     }
//   }

//   Future loadModel() async {
//     try {
//       this.interpreter =
//           await tfl.Interpreter.fromAsset('mobilefacenet.tflite');

//       print(
//           '**********\n Loaded successfully model mobilefacenet.tflite \n*********\n');
//     } catch (e) {
//       print('Failed to load model.');
//       print(e);
//     }
//     FaceAntiSpoofing.loadSpoofModel();
//   }

//   Future<void> _initializeCamera() async {
//     await loadModel();
//     if (_camera != null) {
//       await _camera?.dispose();
//     }
//     final CameraDescription description =
//         await ScannerUtils.getCamera(_direction);

//     if (_direction == CameraLensDirection.front) {
//       _camPos = false;
//     } else {
//       _camPos = true;
//     }

//     _camera = CameraController(
//       description,
//       defaultTargetPlatform == TargetPlatform.iOS
//           ? ResolutionPreset.medium
//           : ResolutionPreset.medium,
//       enableAudio: false,
//     );

//     /*  void showInSnackBar(String message) {
//       // ignore: deprecated_member_use
//       _scaffoldKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
//     } */

//     // If the controller is updated then update the UI.
//     _camera?.addListener(() {
//       if (mounted) setState(() {});
//       if (_camera!.value.hasError) {
//         print("Camera error ${_camera!.value.errorDescription}");
//         // showInSnackBar('Camera error ${_camera!.value.errorDescription}');
//       }
//     });

//     await _camera?.initialize();
//     //Load file from assets directory to store the detected faces
//     _savedFacesDir = await getApplicationDocumentsDirectory();
//     String _fullPathSavedFaces = _savedFacesDir!.path + '/savedFaces.json';
//     jsonFile = new File(_fullPathSavedFaces);

//     if (jsonFile!.existsSync()) {
//       data = json.decode(jsonFile!.readAsStringSync());
//       print('Saved faced from memory: ' + data.toString());
//     }
//     await _camera?.startImageStream((CameraImage image) {
//       print("camera image  ${image}");
//        print("is detecting  image  ${_isDetecting}");
//       if (_isDetecting) return;
//       _isDetecting = true;

//       String res;
//       dynamic finalResults = Multimap<String, Face>();

//       ScannerUtils.detect(
//         image: image,
//         detectInImage: _getDetectionMethod(),
//         imageRotation: description.sensorOrientation,
//       ).then(
//         (dynamic results) {
//           print("resultsssss ${results}");
//           if (_currentDetector == null) return;
//           if (results.length == 0) {
//             _faceFound = false;
//           } else {
//             _faceFound = true;
//             print("face founddddd ${_faceFound}");
//           }
//           // Start storing faces and use Tensorflow to recognize
//           var croppedBoundary = 0;
//           Face _face;
//           imglib.Image convertedImage = _convertCameraImage(image, _direction);
//           /*
//           if (Platform.isIOS) {
//             if (!_camPos) {
//               convertedImage = imglib.copyRotate(convertedImage, 90);
//             } else {
//               convertedImage = imglib.copyRotate(convertedImage, -90);
//             }
//           }
//           */
//           for (_face in results) {
//             double x, y, w, h;
//             x = (_face.boundingBox.left - croppedBoundary);
//             y = (_face.boundingBox.top - croppedBoundary);
//             w = (_face.boundingBox.width + croppedBoundary);
//             h = (_face.boundingBox.height + croppedBoundary);
//             imglib.Image croppedImage;
//             if (Platform.isAndroid) {
//               croppedImage = imglib.copyCrop(
//                 convertedImage,
//                 y: y.round(),
//                 width: w.round(),
//                 height: h.round(),
//                 x: x.round(),
//               );
//             } else {
//               croppedImage = imglib.copyCrop(convertedImage,
//                   x: x.round(),
//                   y: y.round(),
//                   width: w.round(),
//                   height: h.round());
//             }
//             //Store detected face into
//             _displayBase64FaceImage = base64Encode(imglib.encodeJpg(
//                 imglib.copyResize(croppedImage, width: 200, height: 200)));

//             croppedImage = imglib.copyResizeCropSquare(croppedImage, size: 112);
//             // int startTime = new DateTime.now().millisecondsSinceEpoch;
//             res = _recognizeFace(croppedImage);
//             _faceName = res;
//             //Judge the detected face for anti spoofing purpose
//             if (_enableAntiSpoofing) {
//               spoofDetectOutput =
//                   FaceAntiSpoofing.antiSpoofing(croppedImage);
//             }
//             // int endTime = new DateTime.now().millisecondsSinceEpoch;
//             // print("Inference took ${endTime - startTime}ms");
//             finalResults.add(res, _face);
//           }
//           setState(() {
//             _scanResults = finalResults;
//           });
//         },
//       ).whenComplete(() => Future.delayed(
//           Duration(
//             milliseconds: 100,
//           ),
//           () => {_isDetecting = false}));
//     });
//   }

//   Future<dynamic> Function(GoogleVisionImage image) _getDetectionMethod() {
//     return _faceDetector.processImage;
//   }

//   Widget _buildResults() {
//     const Text noResultsText = Text('No results!');

//     if (_scanResults == null ||
//         _camera == null ||
//         !_camera!.value.isInitialized) {
//       return noResultsText;
//     }

//     CustomPainter painter;

//     final Size imageSize = Size(
//       _camera!.value.previewSize!.height,
//       _camera!.value.previewSize!.width,
//     );

//     assert(_currentDetector == Detector.face);

//     if (_landMarkFace)
//       painter = FaceDetectorLandmarkPainter(imageSize, _scanResults, _camPos);
//     else
//       painter = FaceDetectorNormalPainter(imageSize, _scanResults, _camPos);

//     return CustomPaint(
//       painter: painter,
//     );
//   }

//   Widget _buildImage() {
//     return Container(
//       constraints: const BoxConstraints.expand(),
//       child: _camera == null
//           ? const Center(
//               child: Text(
//                 'Initializing Camera...',
//                 style: TextStyle(
//                   color: Colors.lime,
//                   fontSize: 30,
//                 ),
//               ),
//             )
//           : Stack(
//               fit: StackFit.expand,
//               children: <Widget>[
//                 CameraPreview(_camera!),
//                 _buildResults(),
//               ],
//             ),
//     );
//   }

//   Widget _buildStack() {
//     return Stack(
//       alignment: const Alignment(-1, 1),
//       children: [
//         _buildImage(),
//         CircleAvatar(
//           backgroundColor: Colors.blue,
//           child: CircleAvatar(
//             backgroundColor: Colors.black12,
//             foregroundImage:
//                 (_displayBase64FaceImage != "" && _faceFound && !_addFaceScreen
//                         ? MemoryImage(base64Decode(_displayBase64FaceImage))
//                             as ImageProvider<Object>
//                         : AssetImage('assets/background.jpg'))
//                     as ImageProvider<Object>?,
//             radius: 40,
//           ),
//           radius: 50,
//         ),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Container(
//             decoration: const BoxDecoration(
//               color: Colors.black45,
//             ),
//             child: Text(
//               "${(spoofDetectOutput != null ? spoofDetectOutput : _faceName)}",
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Future<void> _toggleCameraDirection() async {
//     if (_direction == CameraLensDirection.back) {
//       _direction = CameraLensDirection.front;
//       _camPos = false;
//     } else {
//       _direction = CameraLensDirection.back;
//       _camPos = true;
//     }

//     await _camera?.stopImageStream();
//     await _camera?.dispose();

//     setState(() {
//       _camera = null;
//     });

//     await _initializeCamera();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Realtime Face Recognition'),
//         actions: <Widget>[
//           PopupMenuButton<Choice>(
//             onSelected: (Choice result) {
//               if (result == Choice.delete)
//                 _resetFile();
//               else if (result == Choice.view)
//                 _viewLabels();
//               else if (result == Choice.landmarkFace)
//                 _landMarkFace = true;
//               else if (result == Choice.normalFace)
//                 _landMarkFace = false;
//               else if (result == Choice.antiSpoofing)
//                 _enableAntiSpoofing = true;
//               else if (result == Choice.removeSpoofing)
//                 _enableAntiSpoofing = false;
//             },
//             itemBuilder: (BuildContext context) => <PopupMenuEntry<Choice>>[
//               const PopupMenuItem<Choice>(
//                 value: Choice.view,
//                 child: Text('View Saved Faces'),
//               ),
//               const PopupMenuItem<Choice>(
//                 value: Choice.delete,
//                 child: Text('Remove All Faces'),
//               ),
//               const PopupMenuItem<Choice>(
//                 value: Choice.landmarkFace,
//                 child: Text('Landmark Faces'),
//               ),
//               const PopupMenuItem<Choice>(
//                 value: Choice.normalFace,
//                 child: Text('Normal Faces'),
//               ),
//               const PopupMenuItem<Choice>(
//                 value: Choice.antiSpoofing,
//                 child: Text('Enable AntiSpoofing'),
//               ),
//               const PopupMenuItem<Choice>(
//                 value: Choice.removeSpoofing,
//                 child: Text('Disable AntiSpoofing'),
//               ),
//             ],
//           ),
//         ],
//       ),
//       body: _buildStack(),
//       floatingActionButton:
//           Column(mainAxisAlignment: MainAxisAlignment.end, children: [
//         FloatingActionButton(
//           backgroundColor: (_faceFound) ? Colors.blue : Colors.blueGrey,
//           child: Icon(Icons.add),
//           onPressed: () {
//             if (_faceFound) _addLabel();
//           },
//         ),
//         SizedBox(
//           height: 10,
//         ),
//         FloatingActionButton(
//           onPressed: _toggleCameraDirection,
//           child: _direction == CameraLensDirection.back
//               ? const Icon(Icons.camera_front)
//               : const Icon(Icons.camera_rear),
//         ),
//       ]),
//     );
//   }

//   String _recognizeFace(imglib.Image img) {
//     List input = ScannerUtils.imageToByteListFloat32(img, 112, 128, 128);
//     input = input.reshape([1, 112, 112, 3]);
//     List output = List.generate(1, (index) => List.filled(192, 0));

//     interpreter?.run(input, output);
//     output = output.reshape([192]);
//     _predictedData = List.from(output);
//     return _compareExistSavedFaces(_predictedData!).toUpperCase();
//   }

//   String _compareExistSavedFaces(List currEmb) {
//     if (data.length == 0) return "No Face saved";
//     double minDist = 999;
//     double currDist = 0.0;
//     String predRes = "NOT RECOGNIZED";
//     for (String label in data.keys) {
//       currDist = ScannerUtils.euclideanDistance(data[label], currEmb);
//       if (currDist <= threshold && currDist < minDist) {
//         minDist = currDist;
//         predRes = label;
//       }
//     }
//     print(minDist.toString() + " " + predRes);
//     return predRes;
//   }

//   void _resetFile() {
//     data = {};
//     jsonFile?.deleteSync();
//   }

//   void _viewLabels() {
//     setState(() {
//       _camera = null;
//     });
//     String name;
//     var alert = new AlertDialog(
//       title: new Text("Saved Faces"),
//       content: Container(
//         height: 100.0,
//         width: 300.0,
//         child: new ListView.builder(
//             padding: new EdgeInsets.all(2),
//             itemCount: data.length,
//             itemBuilder: (BuildContext context, int index) {
//               name = data.keys.elementAt(index);
//               return new Column(
//                 children: <Widget>[
//                   new ListTile(
//                     title: new Text(
//                       name,
//                       style: new TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[400],
//                       ),
//                     ),
//                   ),
//                   new Padding(
//                     padding: EdgeInsets.all(2),
//                   ),
//                   new Divider(),
//                 ],
//               );
//             }),
//       ),
//       actions: <Widget>[
//         new TextButton(
//           child: Text("OK"),
//           onPressed: () {
//             _initializeCamera();
//             Navigator.pop(context);
//           },
//         )
//       ],
//     );
//     showDialog(
//         context: context,
//         builder: (context) {
//           return alert;
//         });
//   }

//   void _addLabel() {
//     setState(() {
//       _camera = null;
//     });
//     print("Adding new face");
//     _addFaceScreen = true;
//     var alert = new AlertDialog(
//       scrollable: true,
//       title: new Text("Add Face"),
//       content: new Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//             ),
//             child: _displayBase64FaceImage != "" && _faceFound
//                 ? Image.memory(
//                     (base64Decode(_displayBase64FaceImage)),
//                     height: 200,
//                   )
//                 : Image.asset(
//                     'assets/background.jpg',
//                     height: 200,
//                   ),
//           ),
//           Container(
//             child: new TextField(
//               controller: _name,
//               autofocus: true,
//               decoration: new InputDecoration(
//                   labelText: "Name", icon: new Icon(Icons.face)),
//             ),
//           )
//         ],
//       ),
//       actions: <Widget>[
//         new TextButton(
//             child: Text("Save"),
//             onPressed: () {
//               _handleWriteJSON(_name.text.toUpperCase());
//               _name.clear();
//               Navigator.pop(context);
//             }),
//         new TextButton(
//           child: Text("Cancel"),
//           onPressed: () {
//             _initializeCamera();
//             Navigator.pop(context);
//           },
//         )
//       ],
//     );
//     showDialog(
//         context: context,
//         builder: (context) {
//           return alert;
//         });
//     _addFaceScreen = false;
//   }

//   void _handleWriteJSON(String text) {
//     data[text] = _predictedData;
//     jsonFile?.writeAsStringSync(json.encode(data));
//     _initializeCamera();
//   }

//   static imglib.Image _convertCameraImage(
//       CameraImage image, CameraLensDirection _dir) {
//     imglib.Image img = imglib.Image(width: 0, height: 0);
//     print("image format group ${image.format.group}");
//     try {
//       if (image.format.group == ImageFormatGroup.yuv420) {
//         img = _convertYUV420(image, _dir);
//       } else if (image.format.group == ImageFormatGroup.bgra8888) {
//         img = _convertBGRA8888(image, _dir);
//       }

//       return img;
//     } catch (e) {
//       print(">>>>>>>>>>>> ERROR:" + e.toString());
//     }
//     return img;
//   }

//   static imglib.Image _convertBGRA8888(
//       CameraImage image, CameraLensDirection _dir) {
//     var img = imglib.Image.fromBytes(
//         width: image.width,
//         height: image.height,
//         bytes: image.planes[0].bytes.buffer,
//         format: imglib.Format.uint8
//         // format: imglib.Format.bgra,
//         );

//     //var img1 = (_dir == CameraLensDirection.front)
//     //    ? imglib.copyRotate(img, -90)
//     //    : imglib.copyRotate(img, 90);
//     return img;
//   }

  

//   static imglib.Image _convertYUV420(
//       CameraImage image, CameraLensDirection _dir) {
//     int width = image.width;
//     int height = image.height;
//     var img = imglib.Image(
//       width: width,
//       height: height,
//     );
//     const int hexFF = 0xFF000000;
//     final int uvyButtonStride = image.planes[1].bytesPerRow;
//     final int uvPixelStride = image.planes[1].bytesPerPixel ?? 0;
//     for (int x = 0; x < width; x++) {
//       for (int y = 0; y < height; y++) {
//         final int uvIndex =
//             uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
//         final int index = y * width + x;
//         final yp = image.planes[0].bytes[index];
//         final up = image.planes[1].bytes[uvIndex];
//         final vp = image.planes[2].bytes[uvIndex];
//         int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
//         int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
//             .round()
//             .clamp(0, 255);
//         int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

//         img.setPixelRgba(height - y, x, r, g, b,hexFF);

//         // img.data[index] = hexFF | (b << 16) | (g << 8) | r;
//       }
//     }
//     var img1 = (_dir == CameraLensDirection.front)
//         ? imglib.copyRotate(img, angle: -90)
//         : imglib.copyRotate(img, angle: 90);
//     return img1;
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     WidgetsBinding.instance.removeObserver(this);
//     _camera?.dispose().then((_) {
//       _faceDetector.close();
//     });
//     _currentDetector = Detector.face;
//   }
// }
