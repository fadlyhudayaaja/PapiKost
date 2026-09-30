import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/mock_service.dart';
import '../../../../data/models/kost_model.dart';

enum MessageSender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<KostModel>? kostSuggestions;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.kostSuggestions,
  });
}

class PapibotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isBotTyping = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isBotTyping => _isBotTyping;

  PapibotProvider() {
    _messages.add(
      ChatMessage(
        id: 'welcome',
        text:
            'Halo! Saya PapiBot 🤖\n\n'
            'Asisten AI PapiKost yang siap membantu Anda mencari kost di Medan.\n\n'
            'Coba tanyakan:\n'
            '• "Cari kost putri dekat USU harga di bawah 1.2 juta"\n'
            '• "Kost yang bisa patungan"\n'
            '• "Kost campur dengan WiFi dan AC"',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ),
    );
    _isBotTyping = true;
    notifyListeners();

    try {
      final response = await _callGeminiApi(text);
      final suggestions = await _getSuggestions(text);

      _isBotTyping = false;
      _messages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_bot',
          text: response,
          sender: MessageSender.bot,
          timestamp: DateTime.now(),
          kostSuggestions: suggestions.isNotEmpty ? suggestions : null,
        ),
      );
    } catch (_) {
      _isBotTyping = false;
      _messages.add(
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          text: 'Maaf, saya sedang mengalami gangguan. Silakan coba lagi.',
          sender: MessageSender.bot,
          timestamp: DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  Future<String> _callGeminiApi(String userMessage) async {
    // Tanpa API key → pakai fallback
    if (AppConstants.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      // Simulasi delay berpikir
      await Future.delayed(const Duration(milliseconds: 800));
      return _getFallbackResponse(userMessage);
    }

    final dio = Dio();
    try {
      final response = await dio.post(
        '${AppConstants.geminiBaseUrl}?key=${AppConstants.geminiApiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Kamu adalah PapiBot, asisten AI untuk aplikasi PapiKost. '
                      'Fokus membantu pencarian kost di Medan, khususnya area USU. '
                      'Berikan respons singkat (maks 150 kata) dalam Bahasa Indonesia yang ramah. '
                      'Pertanyaan pengguna: $userMessage',
                },
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 250},
        },
      );
      final candidates = response.data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'] as String;
      }
      return _getFallbackResponse(userMessage);
    } on DioException {
      return _getFallbackResponse(userMessage);
    }
  }

  Future<List<KostModel>> _getSuggestions(String query) async {
    final q = query.toLowerCase();
    final hasKostIntent =
        q.contains('kost') ||
        q.contains('sewa') ||
        q.contains('kamar') ||
        q.contains('rekomendasikan') ||
        q.contains('cari');

    if (!hasKostIntent) return [];

    // Ambil dari MockService lalu filter berdasarkan query
    final all = await MockService.fetchKostList();
    return all
        .where((k) {
          if (q.contains('putri') && k.type != 'PUTRI') return false;
          if (q.contains('putra') && k.type != 'PUTRA') return false;
          if (q.contains('patungan') && !k.isSplitBillAvailable) return false;
          if ((q.contains('murah') || q.contains('800') || q.contains('900')) &&
              k.pricePerMonth > 1000000)
            return false;
          return true;
        })
        .take(3)
        .toList();
  }

  String _getFallbackResponse(String query) {
    final q = query.toLowerCase();
    if (q.contains('harga') || q.contains('murah') || q.contains('budget')) {
      return 'Untuk kost dengan harga terjangkau di Medan, saya punya beberapa rekomendasi! '
          'Harga mulai dari Rp 800.000/bulan. Lihat pilihan di bawah 👇';
    }
    if (q.contains('patungan') || q.contains('split')) {
      return 'Fitur Sewa Patungan PapiKost memungkinkan kamu berbagi biaya 2–4 orang. '
          'Hemat lebih banyak bersama teman! Ini kost yang bisa patungan 👇';
    }
    if (q.contains('putri')) {
      return 'Kost khusus putri yang nyaman dan aman di Medan. '
          'Semua dengan keamanan terjamin. Ini rekomendasinya 👇';
    }
    if (q.contains('putra')) {
      return 'Kost putra strategis di sekitar USU dan Fasilkom. '
          'Akses mudah ke kampus! Ini pilihannya 👇';
    }
    if (q.contains('ac') || q.contains('wifi') || q.contains('fasilitas')) {
      return 'Berikut kost dengan fasilitas lengkap termasuk WiFi dan AC di Medan 👇';
    }
    if (q.contains('usu') || q.contains('fasilkom') || q.contains('kampus')) {
      return 'Kost-kost strategis dekat kampus USU Medan yang bisa saya rekomendasikan 👇';
    }
    return 'Berikut beberapa kost yang mungkin sesuai kebutuhan kamu di Medan 👇';
  }

  void clearMessages() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Halo! Saya PapiBot 🤖\n\nAda yang bisa saya bantu?',
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
