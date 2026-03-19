import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AiService {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://smart-expense-ai-backend.onrender.com';
    }

    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://192.168.1.5:8000';
    return 'http://127.0.0.1:8000';
  }

  static Future<Map<String, dynamic>?> analyzeExpense(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/predict'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        debugPrint('Lỗi Server AI: ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Lỗi: Quá thời gian kết nối đến Server AI (Timeout)');
      return null;
    } catch (e) {
      debugPrint('Lỗi kết nối AI: $e');
      return null;
    }
  }
}
