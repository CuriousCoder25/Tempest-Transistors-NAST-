import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/assistant_reply.dart';

class AssistantFailure implements Exception {
  const AssistantFailure(this.message);
  final String message;
}

class AssistantApi {
  AssistantApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  factory AssistantApi.configured() {
    const configured = String.fromEnvironment('API_BASE_URL');
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final local = android ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
    return AssistantApi(baseUrl: configured.isEmpty ? local : configured);
  }

  final String baseUrl;
  final http.Client _client;

  Future<AssistantReply> send({
    required String sessionId,
    required String message,
  }) async {
    try {
      final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      final response = await _client
          .post(
            base.resolve('assistant'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'session_id': sessionId, 'message': message}),
          )
          .timeout(const Duration(seconds: 42));
      if (response.statusCode != 200) {
        throw const AssistantFailure(
          'The assistant is unavailable right now. Please try again.',
        );
      }
      return AssistantReply.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Json,
      );
    } on TimeoutException {
      throw const AssistantFailure(
        'The assistant timed out. Please try again.',
      );
    } on http.ClientException {
      throw const AssistantFailure(
        'Could not reach the assistant. Please try again.',
      );
    } on FormatException {
      throw const AssistantFailure(
        'Could not read the response. Please try again.',
      );
    } on TypeError {
      throw const AssistantFailure(
        'Could not read the response. Please try again.',
      );
    } on StateError {
      throw const AssistantFailure(
        'Could not read the response. Please try again.',
      );
    }
  }

  void close() => _client.close();
}
