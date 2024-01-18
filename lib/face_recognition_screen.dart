import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:samert_camera_flutter/antispoofing_folder/anti_spoofing.dart';


class FaceRecognitionView extends StatefulWidget {
  const FaceRecognitionView({
    super.key,
  });

  @override
  State<FaceRecognitionView> createState() => _FaceRecognitionViewState();
}

class _FaceRecognitionViewState extends State<FaceRecognitionView> {
  File? faceRecog;
  Face? detectedFace;
  File? cropSaveFile;
  File? _capturedImage;

  //antispoofing

  String? punchtype;

  
  String? antiSpoofingScore;
  String base64File = '';
  String base64Image = '';
  File base64toFile = File('');

  
  DetectedFace? _detectedFace;
  bool autoCapture = false;
  img.Image? cropImage;
  // FaceAntiSpoofing faceAntiSpoofing = FaceAntiSpoofing();

  @override
  void initState() {
    super.initState();
    print("initcalled");
     FaceAntiSpoofing.loadSpoofModel();

   
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("widget called ");
    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          title: const Text('FaceCamera example app'),
        ),
        body: SmartFaceCamera(
            showControls: false,
            autoCapture: true,
            defaultCameraLens: CameraLens.front,
            onCapture: (File? image)  {
              if (image != null) {
                // Replace the captured image with the new one
                _capturedImage = image;
                print("captured image path is ${image.path}");

                // await cropImage(base64toFile, context);
              }
            },
            onFaceDetected: (Face? face, img.Image? image)  {
              
              print("Face detected ${face?.boundingBox}");
              setState(() {
                detectedFace = face;
                cropImage = image;
               antiSpoofingScore =  FaceAntiSpoofing.antiSpoofing(cropImage!);
              });

          
              //Do something
            },
            messageBuilder: (context, face) {
              if (face == null) {
                return _message('Place your face in the camera');
              }
              if (!face.wellPositioned) {
                return _message('Center your face in the square');
              }
              return const SizedBox.shrink();
            }),
        bottomSheet: Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(
                img.encodePng(cropImage ?? img.Image(height: 0, width: 0)),
                width: 200, // Set the width as needed
                height: 200, // Set the height as needed
              ),
              SizedBox(height: 5.0),
              Text(
                "${antiSpoofingScore}",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      )
    ]);
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, height: 1.5, fontWeight: FontWeight.w400)),
      );

 
}
