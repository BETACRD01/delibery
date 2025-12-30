// lib/utils/image_orientation_fixer.dart
// Corrige la orientación de imágenes tomadas con la cámara

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Utilidad para corregir la orientación de imágenes basada en datos EXIF.
/// Esto es especialmente necesario para fotos tomadas con la cámara en iOS
/// que pueden aparecer rotadas incorrectamente.
class ImageOrientationFixer {
  /// Corrige la orientación de una imagen y devuelve un nuevo archivo
  /// con la orientación correcta aplicada.
  ///
  /// [imageFile] - El archivo de imagen original
  ///
  /// Retorna un nuevo File con la imagen corregida, o el archivo original
  /// si no se necesita corrección o hay un error.
  static Future<File> fixOrientation(File imageFile) async {
    try {
      // Leer los bytes de la imagen
      final Uint8List bytes = await imageFile.readAsBytes();

      // Decodificar la imagen (esto lee automáticamente el EXIF)
      final img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        // No se pudo decodificar, devolver original
        return imageFile;
      }

      // bakeOrientation aplica la orientación EXIF a los píxeles
      // y resetea el tag de orientación a 1 (normal)
      final img.Image fixedImage = img.bakeOrientation(originalImage);

      // Codificar como JPEG con buena calidad
      final Uint8List fixedBytes = img.encodeJpg(fixedImage, quality: 90);

      // Guardar en un archivo temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = 'fixed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fixedFile = File('${tempDir.path}/$fileName');

      await fixedFile.writeAsBytes(fixedBytes);

      return fixedFile;
    } catch (e) {
      // En caso de error, devolver el archivo original
      return imageFile;
    }
  }

  /// Comprime y corrige la orientación de una imagen.
  /// Útil para subir imágenes al servidor.
  ///
  /// [imageFile] - El archivo de imagen original
  /// [maxWidth] - Ancho máximo de la imagen resultante
  /// [maxHeight] - Alto máximo de la imagen resultante
  /// [quality] - Calidad JPEG (1-100)
  static Future<File> fixAndCompress(
    File imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 85,
  }) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();

      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        return imageFile;
      }

      // Corregir orientación EXIF
      image = img.bakeOrientation(image);

      // Redimensionar si es necesario (mantiene aspect ratio)
      if (image.width > maxWidth || image.height > maxHeight) {
        // Calcular nueva dimensión manteniendo proporción
        double scale = 1.0;
        if (image.width > image.height) {
          scale = maxWidth / image.width;
        } else {
          scale = maxHeight / image.height;
        }

        final newWidth = (image.width * scale).round();
        final newHeight = (image.height * scale).round();

        image = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Codificar con la calidad especificada
      final Uint8List compressedBytes = img.encodeJpg(image, quality: quality);

      // Guardar archivo
      final tempDir = await getTemporaryDirectory();
      final fileName = 'processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File('${tempDir.path}/$fileName');

      await processedFile.writeAsBytes(compressedBytes);

      return processedFile;
    } catch (e) {
      return imageFile;
    }
  }
}
