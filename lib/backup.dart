import 'dart:core';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as imglib;
//import 'package:quiver/collection.dart';

class FaceAntiSpoofingBackup {
  FaceAntiSpoofingBackup._();

  static const String MODEL_FILE = "assets/FaceAntiSpoofing.tflite";
  static const INPUT_IMAGE_SIZE =
  256; // The width and height of the placeholder image that needs feed data
  static const THRESHOLD =
  0.8; // Set a threshold value, greater than this value is considered an attack
  static const ROUTE_INDEX = 6; // Route index observed during training
  static const LAPLACE_THRESHOLD = 50; // Laplace sampling threshold
  static const LAPLACIAN_THRESHOLD = 1000; // Picture clarity judgment threshold
  static tfl.Interpreter? interpreter;
  static int NUM_CHANNELS = 3;
  static int NUM_CLASSES = 8;

  /*
   * Live detection
   */
  static String antiSpoofing(imglib.Image bitmapCrop1) {
    // Live detection
    var score1 = _antiSpoofing(bitmapCrop1);
    print("scoreeeeeeeee $score1");
    return score1.toString();
  }

  static Future loadSpoofModelbackup() async {
    try {
      interpreter = await tfl.Interpreter.fromAsset(MODEL_FILE);

      print('**********\n Loaded successfully model $MODEL_FILE \n*********\n');
    } catch (e) {
      print('Failed to load model.');
      print(e);
    }
  }

  static double _antiSpoofing(imglib.Image bitmap) {
    // Resize the image to INPUT_IMAGE_SIZE x INPUT_IMAGE_SIZE
    imglib.Image bitmapScale =
    imglib.copyResize(bitmap, width: INPUT_IMAGE_SIZE, height: INPUT_IMAGE_SIZE);

    // Normalize the image
    Float32List img = normalizeImage(bitmapScale);

    // Prepare the input array
    Float32List input = img;

    // Prepare the output arrays
    Float32List clssPred = Float32List(NUM_CLASSES);
    Float32List leafNodeMask = Float32List(NUM_CLASSES);

    // Run the interpreter
    Map<int, Object> outputs = {
      interpreter!.getOutputIndex("Identity"): clssPred,
      interpreter!.getOutputIndex("Identity_1"): leafNodeMask,
    };

    interpreter?.runForMultipleInputs([input], outputs);

    print("FaceAntiSpoofing: ${clssPred.toList()}");
    print("FaceAntiSpoofing: ${leafNodeMask.toList()}");

    // Return the final score
    return leafScore1(clssPred, leafNodeMask);
  }

  /*
   * Live detection
   * @param bitmap
   * @return score
   */
  // static double _antiSpoofing(imglib.Image bitmap) {
  //   // Resize the face to a size of 256X256, because the shape of the placeholder that needs feed data below is (1, 256, 256, 3)
  //   imglib.Image bitmapScale = imglib.copyResizeCropSquare(
  //     bitmap,
  //     size: INPUT_IMAGE_SIZE,
  //   );
  //
  //   var img = normalizeImage(bitmapScale);
  //   print("normalised image ${img}");
  //
  //
  //
  //   List input =
  //       new List.generate(1, (index) => List.filled(8, 0.0), growable: true);
  //
  //   input[0] = img.reshape([1, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE, 3]);
  //
  //   List clssPred = new List.generate(1, (index) => List.filled(8, 0.0));
  //   List leafNodeMask = new List.generate(1, (index) => List.filled(8, 0.0));
  //
  //   Map<int, Object> outputs = {};
  //
  //   outputs[interpreter!.getOutputIndex("Identity")] = clssPred;
  //   outputs[interpreter!.getOutputIndex("Identity_1")] = leafNodeMask;
  //
  //   if (input.isNotEmpty &&
  //       outputs.isNotEmpty &&
  //       input.length > 0 &&
  //       outputs.length > 0) {
  //     // interpreter!.runForMultipleInputs([input], outputs);
  //     // print("FaceAntiSpoofing" +
  //     //     "[" +
  //     //     clssPred[0][0].toString() +
  //     //     ", " +
  //     //     clssPred[0][1].toString() +
  //     //     ", " +
  //     //     clssPred[0][2].toString() +
  //     //     ", " +
  //     //     clssPred[0][3].toString() +
  //     //     ", " +
  //     //     clssPred[0][4].toString() +
  //     //     ", " +
  //     //     clssPred[0][5].toString() +
  //     //     ", " +
  //     //     clssPred[0][6].toString() +
  //     //     ", " +
  //     //     clssPred[0][7].toString() +
  //     //     "]\n");
  //     // print("FaceAntiSpoofing" +
  //     //     "[" +
  //     //     leafNodeMask[0][0].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][1].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][2].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][3].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][4].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][5].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][6].toString() +
  //     //     ", " +
  //     //     leafNodeMask[0][7].toString() +
  //     //     "]\n");
  //
  //     return leafScore1(clssPred, leafNodeMask);
  //   } else {
  //     print("ERROR in input/output values");
  //     return -1;
  //   }
  // }

  static dynamic leafScore1(var clssPred, var leafNodeMask) {
    var score = 0.0;
    for (var i = 0; i < 8; i++) {
      var absVar = (clssPred[0][i]).abs();
      score += absVar * leafNodeMask[0][i];
    }
    return score;
  }



  /*
   * Normalize the picture to [0, 1]
   * @param bitmap
   * @return
   */
  // static Float32List normalizeImage(imglib.Image bitmap) {
  //   var h = bitmap.height;
  //   var w = bitmap.width;
  //   var convertedBytes = Float32List(1 * h * w * 3);
  //   var buffer = Float32List.view(convertedBytes.buffer);
  //   var imageStd = 128;
  //   var pixelIndex = 0;
  //
  //   for (var i = 0; i < h; i++) {
  //     // Note that it is height first and then width
  //     for (var j = 0; j < w; j++) {
  //       var pixel = bitmap.getPixel(j, i);
  //       buffer[pixelIndex++] = (pixel.r - imageStd) / imageStd;
  //       buffer[pixelIndex++] = (pixel.g - imageStd) / imageStd;
  //       buffer[pixelIndex++] = (pixel.b - imageStd) / imageStd;
  //     }
  //   }
  //   return convertedBytes.buffer.asFloat32List();
  // }

  static Float32List normalizeImage(imglib.Image image) {
    int h = image.height;
    int w = image.width;
    int imageSize = h * w * NUM_CHANNELS;

    Float32List floatValues = Float32List(imageSize);

    double imageStd = 255.0;

    for (int y = 0, index = 0; y < h; y++) {
      for (int x = 0; x < w; x++, index += NUM_CHANNELS) {
        imglib.Pixel pixel = image.getPixel(x, y);
        double r = pixel.r / imageStd;
        double g = pixel.g / imageStd;
        double b = pixel.b / imageStd;

        floatValues[index] = r;
        floatValues[index + 1] = g;
        floatValues[index + 2] = b;
      }
    }

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
