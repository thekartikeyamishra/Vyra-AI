import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class WatermarkUtils {
  /// **Overlay Watermark**
  /// Takes raw image bytes, draws the "Vyra AI" branding on the bottom right,
  /// and returns the new image bytes.
  static Future<Uint8List> addWatermark(Uint8List originalImageBytes) async {
    try {
      // 1. Decode the image (Hydrate bytes to a usable Image object)
      final ui.Codec codec = await ui.instantiateImageCodec(originalImageBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      // 2. Setup Canvas for Drawing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Use the image's dimensions
      final width = originalImage.width.toDouble();
      final height = originalImage.height.toDouble();
      final size = Size(width, height);

      // 3. Draw the Original Image
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // 4. Configure Watermark Style
      // Adaptive size based on image resolution (approx 5% of height)
      final fontSize = height * 0.05; 
      
      const textStyle = TextStyle(
        color: Colors.white,
        fontFamily: 'Roboto', // Or your app's font
        fontWeight: FontWeight.bold,
        shadows: [
          // Drop shadow for visibility on bright backgrounds
          Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(2.0, 2.0)),
        ],
      );

      final textSpan = TextSpan(
        text: 'Generated with Vyra AI',
        style: textStyle.copyWith(fontSize: fontSize),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.end,
      );

      // 5. Layout & Position Text
      textPainter.layout(maxWidth: width);
      
      // Position: Bottom Right with some padding
      final padding = width * 0.03;
      final xPosition = width - textPainter.width - padding;
      final yPosition = height - textPainter.height - padding;
      
      final offset = Offset(xPosition, yPosition);

      // 6. Paint Text onto Canvas
      textPainter.paint(canvas, offset);

      // 7. Finalize Image
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      
      // 8. Convert back to Bytes (PNG format for high quality)
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to encode watermarked image.");
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("⚠️ Watermark Error: $e");
      // Fallback: Return original image if watermarking fails
      return originalImageBytes;
    }
  }
}