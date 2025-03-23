import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static const int keyLength = 32; // 256-bit AES key
  static final _secureStorage = const FlutterSecureStorage();

  static Future<Uint8List> _generateRandomKey() async {
    final randomKey = List<int>.generate(keyLength, (i) => (i * 31) % 256);
    return Uint8List.fromList(randomKey);
  }

  static Future<String> encrypt(String text, String storageKey) async {
    if (text.isEmpty) return text;

    final keyBytes = await _generateRandomKey();
    final key = Key(keyBytes);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    _secureStorage.write(key: storageKey, value: base64.encode(keyBytes));

    final encrypted = encrypter.encrypt(text, iv: iv);
    return "${base64.encode(iv.bytes)}:${encrypted.base64}";
  }

  static Future<String> decrypt(String text, String storageKey) async {
    if (text.isEmpty) return text;

    final keyBytes = base64.decode(await _secureStorage.read(key: storageKey) ?? '');
    final key = Key(keyBytes);
    final parts = text.split(':');
    final iv = IV(base64.decode(parts[0]));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    return encrypter.decrypt64(parts[1], iv: iv);
  }

  Future<String> safeDecrypt(String text, String storageKey) async {
    try {
      return await decrypt(text, storageKey);
    } catch (e) {
      return text;
    }
  }
}