// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/template.dart';

class ApiService {
  // 10.0.2.2 is the special loopback IP address mapping to the host's localhost in the Android emulator.
  static String baseUrl = 'http://10.0.2.2:5001';

  static Future<List<Template>> fetchTemplates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/templates/admin'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Template.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load templates: Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error connecting to $baseUrl: $e');
    }
  }

  static Future<bool> createTemplate(Template template) async {
    try {
      final Map<String, dynamic> data = template.toJson();
      data.remove('_id'); // Remove original unique ID so MongoDB auto-generates a new unique entry
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/templates'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      print('SERVER RESPONSE: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('ERROR CREATING TEMPLATE: $e');
      return false;
    }
  }

  static Future<bool> updateTemplate(Template template) async {
    try {
      final Map<String, dynamic> data = template.toJson();
      data.remove('_id'); // Strip ID from payload body to avoid Mongoose immutable path error
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/templates/${template.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      print('SERVER RESPONSE: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('ERROR UPDATING TEMPLATE: $e');
      return false;
    }
  }
}
