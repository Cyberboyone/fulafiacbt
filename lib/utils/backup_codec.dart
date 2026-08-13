import 'dart:convert';

class BackupCodec {
  // Simple key for obfuscation
  static const int _key = 0x5A; 

  static String encode(Map<String, dynamic> data) {
    try {
      final jsonStr = json.encode(data);
      final bytes = utf8.encode(jsonStr);
      
      // Perform simple XOR obfuscation
      final obfuscatedBytes = bytes.map((b) => b ^ _key).toList();
      
      // Convert to Base64
      return base64.encode(obfuscatedBytes);
    } catch (e) {
      return '';
    }
  }

  static Map<String, dynamic>? decode(String code) {
    try {
      final obfuscatedBytes = base64.decode(code.trim());
      
      // Perform reverse XOR
      final bytes = obfuscatedBytes.map((b) => b ^ _key).toList();
      
      final jsonStr = utf8.decode(bytes);
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
