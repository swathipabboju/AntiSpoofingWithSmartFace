/* import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceAntiSpoofing {
  late Interpreter interpreter;

  FaceAntiSpoofing(AssetManager assetManager) {
    final options = InterpreterOptions()..numThreads = 4;
    interpreter = Interpreter.fromAsset("FaceAntiSpoofing.tflite", options: options);
  }

  Future<double> antiSpoofing(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final img = normalizeImage(byteData!);
    final input = [img];

    final clss_pred = List.generate(1, (index) => List.filled(8, 0.0));
    final leaf_node_mask = List.generate(1, (index) => List.filled(8, 0.0));

    final outputs = {interpreter.getOutputIndex("Identity"): clss_pred, interpreter.getOutputIndex("Identity_1"): leaf_node_mask};
    interpreter.run(input, outputs);

    print("FaceAntiSpoofing: ${clss_pred[0]}");
    print("FaceAntiSpoofing: ${leaf_node_mask[0]}");

    return leafScore1(clss_pred, leaf_node_mask);
  }

  double leafScore1(List<List<double>> clss_pred, List<List<double>> leaf_node_mask) {
    var score = 0.0;
    for (var i = 0; i < 8; i++) {
      score += (clss_pred[0][i].abs() * leaf_node_mask[0][i]);
    }
    return score;
  }

  Future<int> laplacian(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final laplace = [
      [0, 1, 0],
      [1, -4, 1],
      [0, 1, 0]
    ];
    final size = laplace.length;
    final img = convertGreyImg(byteData!);
    final height = img.length;
    final width = img[0].length;
    var score = 0;
    for (var x = 0; x < height - size + 1; x++) {
      for (var y = 0; y < width - size + 1; y++) {
        var result = 0;
        for (var i = 0; i < size; i++) {
          for (var j = 0; j < size; j++) {
            result += (img[x + i][y + j] & 0xFF) * laplace[i][j];
          }
        }
        if (result > LAPLACE_THRESHOLD) {
          score++;
        }
      }
    }
    return score;
  }

  static const String MODEL_FILE = "FaceAntiSpoofing.tflite";
  static const int INPUT_IMAGE_SIZE = 256;
  static const double THRESHOLD = 0.8;
  static const int LAPLACE_THRESHOLD = 50;
  static const int LAPLACIAN_THRESHOLD = 300;

  List<List<List<double>>> normalizeImage(ByteData byteData) {
    final width = byteData.widthInPixels;
    final height = byteData.heightInPixels;
    final floatValues = List.generate(height, (i) => List.generate(width, (j) => [0.0, 0.0, 0.0]));

    final imageStd = 255.0;
    final pixels = Uint8List.view(byteData.buffer.asUint8List());
    for (var i = 0; i < height; i++) {
      for (var j = 0; j < width; j++) {
        final val = pixels[i * width + j];
        final r = (val >> 16 & 0xFF) / imageStd;
        final g = (val >> 8 & 0xFF) / imageStd;
        final b = (val & 0xFF) / imageStd;
        floatValues[i][j] = [r, g, b];
      }
    }
    return floatValues;
  }

  List<List<int>> convertGreyImg(ByteData byteData) {
    final width = byteData.widthInPixels;
    final height = byteData.heightInPixels;
    final img = List.generate(height, (i) => List.generate(width, (j) => 0));

    final pixels = Uint8List.view(byteData.buffer.asUint8List());
    for (var i = 0; i < height; i++) {
      for (var j = 0; j < width; j++) {
        final val = pixels[i * width + j];
        img[i][j] = val;
      }
    }
    return img;
  }
}
 */