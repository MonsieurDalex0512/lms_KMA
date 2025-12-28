import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  final _storage = const FlutterSecureStorage();
  
  encrypt.Key _generateKeyFromGroupId(int groupId) {
    final keyString = 'chat_group_$groupId';
    final bytes = utf8.encode(keyString);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }
  
  Future<String> encryptMessage(String message, int groupId) async {
    try {
      final key = _generateKeyFromGroupId(groupId);
      final iv = encrypt.IV.fromLength(16);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(message, iv: iv);
      
      final combined = {
        'iv': base64Encode(iv.bytes),
        'data': encrypted.base64,
      };
      
      return base64Encode(utf8.encode(json.encode(combined)));
    } catch (e) {
      print('Encryption error: $e');
      rethrow;
    }
  }
  
  Future<String> decryptMessage(String encryptedMessage, int groupId) async {
    try {
      final key = _generateKeyFromGroupId(groupId);
      
      final decodedMessage = utf8.decode(base64Decode(encryptedMessage));
      final combined = json.decode(decodedMessage);
      
      final iv = encrypt.IV(base64Decode(combined['iv']));
      final encryptedData = encrypt.Encrypted.fromBase64(combined['data']);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      
      return decrypted;
    } catch (e) {
      print('Decryption error: $e');
      return '[Không thể giải mã tin nhắn]';
    }
  }
  
  Future<void> deleteGroupKey(int groupId) async {
  }
}
