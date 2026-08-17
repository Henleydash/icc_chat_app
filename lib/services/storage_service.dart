import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Envoie les images et documents vers Cloudinary (service gratuit, sans
/// carte bancaire requise) plutôt que Firebase Storage — Firebase impose
/// désormais le forfait payant Blaze pour Storage, ce que ce projet évite.
///
/// Fonctionne avec un "unsigned upload preset" : un mode d'envoi de
/// Cloudinary qui ne nécessite aucune clé secrète côté client, uniquement
/// un nom de compte (cloud name) et le nom du preset. Voir le README pour
/// la configuration (2 minutes, gratuit, sans carte).
class StorageService {
  // ⚠️ Remplace ces deux valeurs par les tiennes (voir README, section
  // Cloudinary). Sans ça, les envois échoueront.
  static const String _cloudName = 'q68kbnq0';
  static const String _uploadPreset = 'icc_chat_unsigned';

  Future<String> _upload(File file, {required String resourceType, required String folder}) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception("Échec de l'envoi (code ${response.statusCode}). "
          "Vérifie le cloud name et l'upload preset dans storage_service.dart.");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['secure_url'] as String;
  }

  Future<String> uploadProfilePhoto(String uid, File file) {
    return _upload(file, resourceType: 'image', folder: 'profile_photos/$uid');
  }

  Future<String> uploadPostImage(String postAuthorId, File file) {
    return _upload(file, resourceType: 'image', folder: 'post_images/$postAuthorId');
  }

  Future<String> uploadChatImage(String chatId, File file) {
    return _upload(file, resourceType: 'image', folder: 'chat_media/$chatId');
  }

  /// Pour les documents (PDF, Word, etc.) : Cloudinary les traite comme des
  /// ressources "raw" plutôt que des images.
  Future<String> uploadChatFile(String chatId, File file, String fileName) {
    return _upload(file, resourceType: 'raw', folder: 'chat_files/$chatId');
  }
}
