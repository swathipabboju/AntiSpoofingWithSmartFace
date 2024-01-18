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
    /*  WidgetsBinding.instance.addPostFrameCallback((_) async {
      print("puch type in face recognition $punchtype");
      _controller = CameraController(
          _cameras ??
              CameraDescription(
                  name: "name",
                  lensDirection: CameraLensDirection.front,
                  sensorOrientation: 1),
          ResolutionPreset.medium,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888,
          enableAudio: false);
      print("faceAntiSpoofing ${faceAntiSpoofing}");
    }); */
   
  }

 /*  void _loadModel() async {
    print("load model");
    // Initialize an instance of FaceAntiSpoofing and load the model
    faceAntiSpoofing = FaceAntiSpoofing();
    await faceAntiSpoofing
        .loadModelImage(cropImage ?? img.Image(height: 0, width: 0));
    print("loaded");
  } */

  /* static Future<DetectedFace?> _detectFace({required visionImage}) async {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    );
    final faceDetector = FaceDetector(
      options: options,
    );
    try {
      final List<Face> faces = await faceDetector.processImage(visionImage);

      print("length of faces --------- ${faces.length} ");

      if (faces.length > 0 && faces.length == 1) {
        final faceDetect = _extractFace(faces);

        print("faceDetect --------: $faceDetect");
        return faceDetect;
      } else {
        print("more than one face detected");
        return null;
      }
    } catch (error) {
      debugPrint(error.toString());
      return null;
    }
  }

  static _extractFace(List<Face> faces) {
    //List<Rect> rect = [];
    bool wellPositioned = faces.isNotEmpty;
    Face? detectedFace;

    for (Face face in faces) {
      // rect.add(face.boundingBox);
      detectedFace = face;

      // Head is rotated to the right rotY degrees
      if (face.headEulerAngleY! > 2 || face.headEulerAngleY! < -2) {
        wellPositioned = false;
      }

      // Head is tilted sideways rotZ degrees
      if (face.headEulerAngleZ! > 2 || face.headEulerAngleZ! < -2) {
        wellPositioned = false;
      }

      // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      // eyes, cheeks, and nose available):
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      final FaceLandmark? rightEar = face.landmarks[FaceLandmarkType.rightEar];
      if (leftEar != null && rightEar != null) {
        if (leftEar.position.y < 0 ||
            leftEar.position.x < 0 ||
            rightEar.position.y < 0 ||
            rightEar.position.x < 0) {
          wellPositioned = false;
        }
      }

      if (face.leftEyeOpenProbability != null) {
        if (face.leftEyeOpenProbability! < 0.5) {
          wellPositioned = false;
        }
      }

      if (face.rightEyeOpenProbability != null) {
        if (face.rightEyeOpenProbability! < 0.5) {
          wellPositioned = false;
        }
      }
    }

    print("wellPositioned ----- ${wellPositioned}");
    print("detectedfaces ----- ${detectedFace}");

    return DetectedFace(wellPositioned: wellPositioned, face: detectedFace);
  } */

  /* img.Image _convertNV21(CameraImage image) {
    final width = image.width.toInt();
    final height = image.height.toInt();

    Uint8List yuv420sp = image.planes[0].bytes;

    final outImg = img.Image(width: width, height: height);
    final int frameSize = width * height;

    for (int j = 0, yp = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width, u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & yuv420sp[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & yuv420sp[uvp++]) - 128;
          u = (0xff & yuv420sp[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = (y1192 + 1634 * v);
        int g = (y1192 - 833 * v - 400 * u);
        int b = (y1192 + 2066 * u);

        if (r < 0)
          r = 0;
        else if (r > 262143) r = 262143;
        if (g < 0)
          g = 0;
        else if (g > 262143) g = 262143;
        if (b < 0)
          b = 0;
        else if (b > 262143) b = 262143;

        // I don't know how these r, g, b values are defined, I'm just copying what you had bellow and
        // getting their 8-bit values.
        /*  outImg.setPixelRgba(i, j, ((r << 6) & 0xff0000) >> 16,
            ((g >> 2) & 0xff00) >> 8, (b >> 10) & 0xff); */
        outImg.setPixelRgba(
          i,
          j,
          ((r << 6) & 0xff0000) >> 16,
          ((g >> 2) & 0xff00) >> 8,
          (b >> 10) & 0xff,
          255,
        );
      }
    }
    return outImg;
  }

  static img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      //format: img.Format.bgra8888,
      width: (image.planes[0].bytesPerRow ~/ 4).round(),
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
    );
  } */

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
            onCapture: (File? image) async {
              if (image != null) {
                // Replace the captured image with the new one
                _capturedImage = image;
                print("captured image path is ${image.path}");

                // await cropImage(base64toFile, context);
              }
            },
            onFaceDetected: (Face? face, img.Image? image) async {
              
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

  img.Image cropFaceImage(img.Image capturedImage) {
    return img.copyCrop(
      capturedImage,
      x: _detectedFace!.face!.boundingBox.left.toInt() /* - 100 */,
      y: _detectedFace!.face!.boundingBox.top.toInt() /* - 100 */,
      width: _detectedFace!.face!.boundingBox.width.toInt() /* + 150 */,
      height: _detectedFace!.face!.boundingBox.height.toInt() /*  + 150 */,
    );
  }
}
