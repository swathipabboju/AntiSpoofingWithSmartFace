import 'dart:core';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imglib;
//import 'package:quiver/collection.dart';

class FaceAntiSpoofing {
FaceAntiSpoofing._();

  static const String MODEL_FILE = "assets/FaceAntiSpoofing.tflite";
  static const INPUT_IMAGE_SIZE =
          256; // The width and height of the placeholder image that needs feed data
  static const THRESHOLD =
          0.2; // Set a threshold value, greater than this value is considered an attack
  static const ROUTE_INDEX = 6; // Route index observed during training
  static const LAPLACE_THRESHOLD = 50; // Laplace sampling threshold
  static const LAPLACIAN_THRESHOLD = 1000; // Picture clarity judgment threshold
  static tfl.Interpreter? interpreter;

  /*
   * Live detection
   */
  static String antiSpoofing(
          imglib.Image bitmapCrop1) {

      print("loadedddddd 6436346345345345");

      // Judge the clarity of the picture before live detection
      // var laplace1 = laplacian(bitmapCrop1);


      String text = "Sharpness detection result left：";
 /*  if (laplace1 < LAPLACIAN_THRESHOLD) {
    text = text + "，" + "False";
  } else { */
      var start = DateTime.now().microsecondsSinceEpoch;

      // Live detection
      var score1 = _antiSpoofing(bitmapCrop1);
      print("scoreeeeeeeee $score1");

      var end = DateTime.now().microsecondsSinceEpoch;

      text = "Sharpness detection result left：" + score1.toString();
      if (score1 < THRESHOLD) {
          text = text + "，" + "True";
      } else {
          text = text + "，" + "False";
      }
      text = text + ".Time consuming: " + (end - start).toString();
  /* }
  print(text); */

      // Judge the clarity of the second picture before live detection
      interpreter?.close();

      return score1.toString();
      
  }

  static Future loadSpoofModel() async {
      try {
          interpreter = await tfl.Interpreter.fromAsset(MODEL_FILE);

          print('**********\n Loaded successfully model $MODEL_FILE \n*********\n');
      } catch (e) {
          print('Failed to load model.');
          print(e);
      }
  }

  /*
   * Live detection
   * @param bitmap
   * @return score
   */
  static double _antiSpoofing(imglib.Image bitmap) {
      // Resize the face to a size of 256X256, because the shape of the placeholder that needs feed data below is (1, 256, 256, 3)
      print("antispoofing called");
      //img.Image? image = img.decodeImage(cropSaveFile!.readAsBytesSync());
      // Resize the image
      imglib.Image resizedImage = imglib.copyResize(bitmap!,
              width: INPUT_IMAGE_SIZE, height: INPUT_IMAGE_SIZE);
      List<List<List<double>>> normalizedImg = normalizeResizedImage(resizedImage);

      List<List<List<List<double>>>> input =
              List.generate(1, (i) => normalizedImg);
      input[0] = normalizedImg;
      // Create output arrays
      List<List<double>> clssPred =
              List.generate(1, (i) => List<double>.filled(8, 0));
      List<List<double>> leafNodeMask =
              List.generate(1, (i) => List<double>.filled(8, 0));

      // Run the interpreter
      if (interpreter != null) {
          Map<int, Object> outputs = {
                  interpreter!.getOutputIndex("Identity"): clssPred,
                  interpreter!.getOutputIndex("Identity_1"): leafNodeMask,
    };

          try {
              interpreter!.runForMultipleInputs([input], outputs);
          } catch (e) {
              print("Error during model inference: $e");
          }
      } else {
          print("interpreter is null");
      }

      return leaf_score1(clssPred, leafNodeMask);
  }

  static double leaf_score1(
          List<List<dynamic>> clssPred, List<List<dynamic>> leafNodeMask) {
      double score = 0;
      for (int i = 0; i < 8; i++) {
          score += clssPred[0][i] * leafNodeMask[0][i];
      }
      print("leaf score  $score");
      return score;
  }

  static dynamic leafScore2(var clssPred) {
      return clssPred[0][ROUTE_INDEX];
  }

  /*
   * Normalize the picture to [0, 1]
   * @param bitmap
   * @return
   */
  static List<List<List<double>>> normalizeResizedImage(imglib.Image resizedImage) {
      int h = resizedImage.height;
      int w = resizedImage.width;
      List<List<List<double>>> floatValues = List.generate(
              h, (i) => List.generate(w, (j) => List<double>.filled(3, 0)));

      for (int i = 0; i < h; i++) {
          for (int j = 0; j < w; j++) {
              imglib.Pixel pixel = resizedImage.getPixel(j, i);
              double r = (pixel.r / 255.0);
              double g = (pixel.g / 255.0);
              double b = (pixel.b / 255.0);

              floatValues[i][j] = [r, g, b];
          }
      }
      // print("normalized imageeeeeeeeeee ${floatValues}");
      return floatValues;
  }

  /*
   * Laplacian algorithm to calculate clarity
   * @param bitmap
   * @return Fraction
   */
  static dynamic laplacian(imglib.Image bitmap) {
      // Resize the face to a size of 256X256, because the shape of the placeholder that needs feed data below is (1, 256, 256, 3)
      imglib.Image bitmapScale =
              imglib.copyResizeCropSquare(bitmap, size: INPUT_IMAGE_SIZE);

      var laplace = [
    [0, 1, 0],
    [1, -4, 1],
    [0, 1, 0]
  ];
      int size = laplace.length;
      var img = imglib.grayscale(bitmapScale);
      int height = img.height;
      int width = img.width;

      int score = 0;
      for (int x = 0; x < height - size + 1; x++) {
          for (int y = 0; y < width - size + 1; y++) {
              int result = 0;
              // Convolution operation on size*size area
              for (int i = 0; i < size; i++) {
                  for (int j = 0; j < size; j++) {
                      // result += (img.getPixel(x + i,y + j) & 0xFF) * laplace[i][j];
                  }
              }
              if (result > LAPLACE_THRESHOLD) {
                  score++;
              }
          }
      }
      return score;
  }
}
