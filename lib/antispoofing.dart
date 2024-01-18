import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;

class FaceAntiSpoofing {
  static const String MODEL_FILE = "assets/FaceAntiSpoofing.tflite";
  static const int INPUT_IMAGE_SIZE = 256;
  static const double THRESHOLD = 0.8;
  static const int ROUTE_INDEX = 6;
  static const int LAPLACE_THRESHOLD = 50;
  static const int LAPLACIAN_THRESHOLD = 250;
  tflite.Interpreter? interpreter;

  Future<double> loadModel(File? cropSaveFile) async {
    try {
      final interpreter = await tflite.Interpreter.fromAsset(MODEL_FILE);
     
      print("interpreter loaded for anti spoofing with image ${interpreter}");
      return antiSpoofing(cropSaveFile);
    } catch (e) {
      print('Error loading model: $e');
      return 0.0;
    }
  }

  loadModelImage(
    img.Image image,
  ) async {
    print("called load model image");
    try {
      interpreter = await tflite.Interpreter.fromAsset(MODEL_FILE);
      print("interpreter loaded for anti spoofing  with image${interpreter}");
      //return antiSpoofingImage(image);
    } catch (e) {
      print('Error loading model: $e');
      //return 0.0;
    }
  }

  double antiSpoofing(File? cropSaveFile) {
    
    img.Image? image = img.decodeImage(cropSaveFile!.readAsBytesSync());
    // Resize the image
    img.Image resizedImage = img.copyResize(image!,
        width: INPUT_IMAGE_SIZE, height: INPUT_IMAGE_SIZE);
    List<List<List<double>>> normalizedImg =
        normalizeResizedImage(resizedImage);

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

  double antiSpoofingImage(img.Image? image) {
    print("antispoofing called");
    //img.Image? image = img.decodeImage(cropSaveFile!.readAsBytesSync());
    // Resize the image
    img.Image resizedImage = img.copyResize(image!,
        width: INPUT_IMAGE_SIZE, height: INPUT_IMAGE_SIZE);
    List<List<List<double>>> normalizedImg =
        normalizeResizedImage(resizedImage);

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

  double leaf_score1(
      List<List<dynamic>> clssPred, List<List<dynamic>> leafNodeMask) {
    double score = 0;
    for (int i = 0; i < 8; i++) {
      score += clssPred[0][i] * leafNodeMask[0][i];
    }
    print("leaf score  $score");
    return score;
  }

  List<List<List<double>>> normalizeResizedImage(img.Image resizedImage) {
    int h = resizedImage.height;
    int w = resizedImage.width;
    List<List<List<double>>> floatValues = List.generate(
        h, (i) => List.generate(w, (j) => List<double>.filled(3, 0)));

    for (int i = 0; i < h; i++) {
      for (int j = 0; j < w; j++) {
        img.Pixel pixel = resizedImage.getPixel(j, i);
        double r = (pixel.r / 255.0);
        double g = (pixel.g / 255.0);
        double b = (pixel.b / 255.0);

        floatValues[i][j] = [r, g, b];
      }
    }
    // print("normalized imageeeeeeeeeee ${floatValues}");
    return floatValues;
  }
}
