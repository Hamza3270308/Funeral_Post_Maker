// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/template.dart';

import 'dart:io' show Platform;

class ApiService {
  // 10.0.2.2 is for Android emulator, 127.0.0.1 is for iOS simulator.
  static String baseUrl = 'http://q14c5cff8kaukmncrx1w60rf.31.97.48.137.sslip.io';

  static String resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('/')) {
      return '$baseUrl$url';
    }
    
    // Replace hardcoded localhost IPs from the web dashboard with the emulator's backend URL
    if (url.startsWith('http://127.0.0.1:5001')) {
      return url.replaceFirst('http://127.0.0.1:5001', baseUrl);
    }
    if (url.startsWith('http://localhost:5001')) {
      return url.replaceFirst('http://localhost:5001', baseUrl);
    }
    if (url.startsWith('http://localhost:3000')) {
      return url.replaceFirst('http://localhost:3000', baseUrl);
    }
    if (url.startsWith('http://127.0.0.1:3000')) {
      return url.replaceFirst('http://127.0.0.1:3000', baseUrl);
    }
    
    return url;
  }

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

  static Future<bool> deleteTemplate(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/templates/$id'),
      );
      print('SERVER RESPONSE DELETE: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('ERROR DELETING TEMPLATE: $e');
      return false;
    }
  }
}
