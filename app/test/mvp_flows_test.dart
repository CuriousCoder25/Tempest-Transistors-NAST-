import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nagarik_sathi/main.dart';
import 'package:nagarik_sathi/screens/assistant_screen.dart';
import 'package:nagarik_sathi/services/assistant_api.dart';
import 'package:nagarik_sathi/services/citizen_voice.dart';
import 'package:nagarik_sathi/widgets/nagarik_ai.dart';

const diagnostic = 'तपाईंसँग अस्पतालको जन्म प्रतिवेदन छ?';

http.Response reply(Map<String, Object?> json) =>
    http.Response.bytes(utf8.encode(jsonEncode(json)), 200);

Map<String, dynamic> requestBody(http.Request request) =>
    jsonDecode(utf8.decode(request.bodyBytes)) as Map<String, dynamic>;

Map<String, Object?> wardQuestion() => {
  'action': 'WARD_OFFICE_GUIDANCE',
  'coverage': 'verified',
  'needs_clarification': true,
  'follow_up_question_nepali': diagnostic,
  'quick_replies_nepali': ['छ', 'छैन'],
};

Future<void> openApp(
  WidgetTester tester,
  Future<http.Response> Function(http.Request) respond, {
  CitizenVoice? voice,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = AssistantApi(
    baseUrl: 'https://example.test',
    client: MockClient(respond),
  );
  addTearDown(api.close);
  await tester.pumpWidget(NagarikSathi(api: api, voice: voice));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

final composer = find.descendant(
  of: find.byType(AssistantScreen),
  matching: find.byType(TextField),
);

Future<void> ask(WidgetTester tester, String question) async {
  await tester.enterText(composer, question);
  await tap(tester, find.byTooltip('Send question'));
}

class TestVoice extends CitizenVoice {
  ValueChanged<String>? _receiveTranscript;
  Completer<bool>? _completion;
  int starts = 0;
  final spoken = <String>[];

  @override
  Future<void> start({required ValueChanged<String> onTranscript}) async {
    _receiveTranscript = onTranscript;
    starts++;
    active = true;
    listening = true;
    amplitude = .65;
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    _receiveTranscript = null;
    active = false;
    listening = false;
    notifyListeners();
  }

  @override
  Future<bool> speakNepali(String text) {
    spoken.add(text);
    _completion = Completer<bool>();
    return _completion!.future;
  }

  @override
  Future<void> stopSpeaking() async {
    final playback = _completion;
    if (playback != null && !playback.isCompleted) playback.complete(false);
  }

  void recognize(String text) {
    final receive = _receiveTranscript!;
    unawaited(cancel());
    receive(text);
  }

  void finishReading() => _completion!.complete(true);
}

Future<void> openDock(WidgetTester tester, TestVoice voice) async {
  final dock = find.byType(NagarikAiRibbon);
  expect(tester.getCenter(dock).dx, 195);
  expect(
    find.descendant(of: dock, matching: find.byType(NagarikAiMark)),
    findsOneWidget,
  );
  expect(voice.starts, 0);
  await tester.tap(dock);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  expect(voice.starts, 1);
  expect(find.text('Listening in Nepali…'), findsOneWidget);
  expect(
    tester
        .widget<NagarikAiListeningMark>(find.byType(NagarikAiListeningMark))
        .amplitude,
    .65,
  );
}

void main() {
  testWidgets('documents and social validation work without an API call', (
    tester,
  ) async {
    await openApp(tester, (_) => throw StateError('Unexpected API call'));
    await tap(tester, find.text('Citizenship'));
    expect(find.text('DEMO MOCKUP'), findsOneWidget);
    expect(find.text('Aarav Sharma'), findsOneWidget);
    await tap(tester, find.byTooltip('Back'));
    await tap(tester, find.text('CIT'));
    await tap(tester, find.text('Check / Submit'));
    expect(find.text('Check the number'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '१२३४५६७८');
    await tap(tester, find.text('Check / Submit'));
    expect(find.text('Valid format'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a complaint draft needs explicit confirmation', (tester) async {
    await openApp(
      tester,
      (_) async => reply({
        'action': 'IN_APP_DEEP_NAV',
        'route': '/complaint',
        'prefill_fields': {
          'category': 'फोहोर',
          'ward_number': '७',
          'description': 'फोहोर उठेको छैन।',
        },
        'field_explanations_nepali': {
          'category': 'समस्याको प्रकार',
          'ward_number': 'समस्या भएको वडा',
        },
        'message_nepali': 'गुनासोको मस्यौदा तयार भयो।',
      }),
    );
    await tap(tester, find.text('Ward Office'));
    await ask(tester, 'वडा ७ मा फोहोर उठेको छैन।');
    expect(find.text('AI Draft — Please Review'), findsNWidgets(3));
    expect(find.text('फोहोर उठेको छैन।'), findsOneWidget);
    expect(find.text('Demo receipt created'), findsNothing);
    await tap(tester, find.text('Confirm & Submit'));
    expect(find.text('Demo receipt created'), findsOneWidget);
    await tap(tester, find.byTooltip('Back'));
    await tap(tester, find.byTooltip('Back'));
    await tap(tester, find.text('Activity'));
    expect(find.text('Complaint (Gunaso)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HIB voice routing selects the requested tab and keeps the draft visible',
    (tester) async {
      await openApp(
        tester,
        (_) async => reply({
          'action': 'IN_APP_DEEP_NAV',
          'route': '/hib',
          'tab': 'renewal',
          'prefill_fields': {'policy_id': 'HIB-DEMO-7', 'district': 'काठमाडौँ'},
          'field_explanations_nepali': {
            'policy_id': 'बीमा परिचय नम्बर',
            'district': 'जिल्लाको नाम',
          },
          'message_nepali': 'नवीकरणको मस्यौदा खोल्दैछु।',
        }),
      );
      await tap(tester, find.text('Ward Office'));
      await ask(tester, 'मेरो बीमा नवीकरण गर्नुहोस्।');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Renewal'))
            .selected,
        isTrue,
      );
      expect(find.text('HIB-DEMO-7'), findsOneWidget);
      expect(find.text('Demo receipt created'), findsNothing);
      await tap(tester, find.text('Confirm & Submit'));
      expect(find.text('Demo receipt created'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a Ward quick reply continues the session and opens a checkable plan',
    (tester) async {
      final messages = <Map<String, dynamic>>[];
      await openApp(tester, (request) async {
        messages.add(requestBody(request));
        if (messages.length == 1) return reply(wardQuestion());
        return reply({
          'action': 'WARD_OFFICE_GUIDANCE',
          'coverage': 'verified',
          'needs_clarification': false,
          'service_nepali': 'जन्म दर्ता',
          'message_nepali': 'सक्कल कागजात लैजानुहोस्।',
          'customized_checklist': [
            {
              'label_nepali': 'अस्पतालको जन्म प्रतिवेदन',
              'status': 'missing',
              'source': {'page': 2},
            },
          ],
          'step_by_step_map': [
            {
              'instruction_nepali': 'वडा कार्यालयमा फारम भर्नुहोस्।',
              'source': {'page': 2},
            },
          ],
        });
      });
      await tap(tester, find.text('Ward Office'));
      await tap(tester, find.text('जन्म दर्ता'));
      await tap(tester, find.text('छैन'));
      expect(messages, hasLength(2));
      expect(messages.last['session_id'], messages.first['session_id']);
      expect(messages.last['message'], 'छैन');
      expect(find.text('Ward Office roadmap'), findsOneWidget);
      expect(find.text('0 of 1 ready'), findsOneWidget);
      await tap(tester, find.byType(CheckboxListTile));
      expect(find.text('1 of 1 ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the logo starts listening and typing cancels it without speech playback',
    (tester) async {
      final voice = TestVoice();
      String? sent;
      await openApp(tester, (request) async {
        sent = requestBody(request)['message'] as String;
        return reply({
          'action': 'SHOW_DOCUMENT',
          'document_id': 'citizenship',
          'message_nepali': 'नागरिकता खोल्दैछु।',
        });
      }, voice: voice);
      await openDock(tester, voice);
      await tap(tester, composer);
      expect(voice.active, isFalse);
      await ask(tester, 'Show my citizenship');
      expect(sent, 'Show my citizenship');
      expect(find.widgetWithText(AppBar, 'Citizenship'), findsOneWidget);
      expect(voice.spoken, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a spoken clarification reopens the mic after Nepali playback', (
    tester,
  ) async {
    final voice = TestVoice();
    final messages = <Map<String, dynamic>>[];
    await openApp(tester, (request) async {
      messages.add(requestBody(request));
      if (messages.length == 1) return reply(wardQuestion());
      return reply({
        'action': 'WARD_OFFICE_GUIDANCE',
        'coverage': 'out_of_scope',
        'message_nepali': 'थप जानकारी उपलब्ध छैन।',
      });
    }, voice: voice);
    await openDock(tester, voice);
    voice.recognize('जन्म दर्ता');
    await tester.pumpAndSettle();
    expect(voice.spoken, [diagnostic]);
    expect(voice.starts, 1);
    voice.finishReading();
    await tester.pump();
    await tester.pump();
    expect(voice.starts, 2);
    expect(find.text('Listening in Nepali…'), findsOneWidget);
    voice.recognize('छ');
    await tester.pumpAndSettle();
    expect(messages.map((message) => message['message']), ['जन्म दर्ता', 'छ']);
    expect(messages.last['session_id'], messages.first['session_id']);
    voice.finishReading();
    await tester.pumpAndSettle();
    expect(voice.starts, 2);
    expect(tester.takeException(), isNull);
  });
}
