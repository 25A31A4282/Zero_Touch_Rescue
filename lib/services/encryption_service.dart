import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // 🔑 16/24/32 characters key
  final Key key = Key.fromUtf8('1234567890123456');
  final IV iv = IV.fromLength(16);

  // 🔒 Encrypt
  String encryptData(String text) {
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return encrypted.base64;
  }

  // 🔓 Decrypt
  String decryptData(String encryptedText) {
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt64(encryptedText, iv: iv);
  }
}