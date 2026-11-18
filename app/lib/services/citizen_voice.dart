import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class CitizenVoice extends ChangeNotifier {
  final _speech = SpeechToText();
  final _tts = FlutterTts();

  ValueChanged<String>? _onTranscript;
  int _turn = 0;
  int _playback = 0;
  bool _disposed = false;
  bool active = false;
  bool listening = false;
  String? error;
  String transcript = '';
  double amplitude = 0;

  Future<void> start({required ValueChanged<String> onTranscript}) async {
    if (active || _disposed) return;
    final turn = ++_turn;
    active = true;
    error = null;
    transcript = '';
    amplitude = 0;
    _onTranscript = onTranscript;
    notifyListeners();
    try {
      await stopSpeaking();
      if (turn != _turn) return;
      final ready = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
        finalTimeout: const Duration(milliseconds: 1200),
      );
      if (turn != _turn) return;
      if (!ready) {
        _finish(
          failure:
              'Microphone or speech recognition is unavailable. You can type below.',
        );
        return;
      }
      final locales = await _speech.locales();
      if (turn != _turn) return;
      var locale = kIsWeb ? 'ne-NP' : 'ne_NP';
      for (final candidate in locales) {
        final id = candidate.localeId.toLowerCase().replaceAll('_', '-');
        if (id == 'ne' || id.startsWith('ne-')) {
          locale = candidate.localeId;
          break;
        }
      }
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          localeId: locale,
          cancelOnError: true,
          partialResults: true,
          listenMode: ListenMode.dictation,
          pauseFor: const Duration(seconds: 2),
          listenFor: const Duration(seconds: 30),
        ),
        onResult: (result) {
          if (turn != _turn || !active) return;
          transcript = result.recognizedWords;
          if (result.finalResult && transcript.trim().isNotEmpty) {
            _finish();
          } else {
            notifyListeners();
          }
        },
        onSoundLevelChange: (level) {
          if (turn != _turn || !active) return;
          final scaled = (level / 12).clamp(0.0, 1.0).toDouble();
          if ((scaled - amplitude).abs() > .08) {
            amplitude = scaled;
            notifyListeners();
          }
        },
      );
    } catch (_) {
      if (turn == _turn && active) {
        _finish(failure: 'Voice input is unavailable. You can type below.');
      }
    }
  }

  void _onStatus(String status) {
    if (!active || _disposed) return;
    if (status == SpeechToText.doneStatus) {
      _finish(
        failure: transcript.trim().isEmpty
            ? 'No speech heard. Try again or type below.'
            : null,
      );
      return;
    }
    final next = status == SpeechToText.listeningStatus;
    if (next != listening) {
      listening = next;
      notifyListeners();
    }
  }

  void _onError(SpeechRecognitionError nativeError) {
    if (!active || _disposed) return;
    final failure = switch (nativeError.errorMsg) {
      'error_no_match' ||
      'error_speech_timeout' => 'No speech heard. Try again or type below.',
      'error_permission' => 'Microphone access is needed for voice input.',
      _ => 'Nepali speech recognition is unavailable. You can type below.',
    };
    _finish(failure: failure);
  }

  void _finish({String? failure}) {
    final callback = _onTranscript;
    final words = transcript.trim();
    _turn++;
    _onTranscript = null;
    active = false;
    listening = false;
    error = failure;
    notifyListeners();
    if (failure == null && words.isNotEmpty) callback?.call(words);
  }

  Future<void> cancel() async {
    _turn++;
    _onTranscript = null;
    active = false;
    listening = false;
    error = null;
    transcript = '';
    if (!_disposed) notifyListeners();
    try {
      await _speech.cancel();
    } catch (_) {
      // The recognizer may already have shut down.
    }
  }

  Future<bool> speakNepali(String text) async {
    final playback = ++_playback;
    try {
      for (final locale in ['ne-NP', 'ne']) {
        final available = await _tts.isLanguageAvailable(locale);
        if (playback != _playback) return false;
        if (available == true || available == 1) {
          await _tts.setLanguage(locale);
          await _tts.setSpeechRate(.46);
          await _tts.awaitSpeakCompletion(true);
          if (playback != _playback) return false;
          final result = await _tts
              .speak(text)
              .timeout(const Duration(seconds: 75));
          return playback == _playback && result != 0;
        }
      }
    } on TimeoutException {
      if (playback == _playback) await stopSpeaking();
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> stopSpeaking() async {
    _playback++;
    try {
      await _tts.stop();
    } catch (_) {
      // Speech synthesis availability depends on the operating system.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(cancel());
    unawaited(stopSpeaking());
    super.dispose();
  }
}
