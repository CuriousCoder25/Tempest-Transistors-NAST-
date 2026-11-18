import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/assistant_reply.dart';
import '../services/assistant_api.dart';
import '../services/citizen_voice.dart';
import '../theme.dart';
import '../widgets/civic_widgets.dart';
import '../widgets/nagarik_ai.dart';
import 'ward_plan_panel.dart';

enum AssistantEntry { wardOffice, nagarikAi }

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.api,
    required this.voice,
    required this.entry,
  });

  final AssistantApi api;
  final CitizenVoice voice;
  final AssistantEntry entry;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen>
    with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();
  final _turns = <(String, AssistantReply, GlobalKey)>[];
  String _sessionId = const Uuid().v4();
  String? _pending;
  String? _error;
  bool _handsFree = false;
  int _voiceSequence = 0;

  bool get _isAiEntry => widget.entry == AssistantEntry.nagarikAi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputFocus.addListener(_onInputFocus);
    if (_isAiEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_inputFocus.hasFocus) _startListening();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopVoice();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopVoice();
    _inputFocus.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onInputFocus() {
    if (_inputFocus.hasFocus) _stopVoice();
  }

  void _stopVoice() {
    _handsFree = false;
    _voiceSequence++;
    unawaited(widget.voice.cancel());
    unawaited(widget.voice.stopSpeaking());
  }

  void _startListening() {
    if (_pending != null ||
        widget.voice.active ||
        ModalRoute.isCurrentOf(context) != true) {
      return;
    }
    _handsFree = true;
    _voiceSequence++;
    _inputFocus.unfocus();
    if (_error != null) setState(() => _error = null);
    unawaited(
      widget.voice.start(onTranscript: (words) => _send(words, spoken: true)),
    );
  }

  void _newConversation() {
    _stopVoice();
    _input.clear();
    setState(() {
      _sessionId = const Uuid().v4();
      _turns.clear();
      _error = null;
    });
  }

  void _scrollToLatest({GlobalKey? key}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      const duration = Duration(milliseconds: 230);
      if (key?.currentContext case final BuildContext anchor) {
        unawaited(
          Scrollable.ensureVisible(anchor, alignment: .04, duration: duration),
        );
        return;
      }
      unawaited(
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: duration,
          curve: Curves.easeOut,
        ),
      );
    });
  }

  Future<void> _send(String text, {bool spoken = false}) async {
    final question = text.trim();
    if (question.isEmpty || _pending != null) return;
    if (question.length > 1200) {
      setState(
        () => _error = 'Enter a question with 1,200 characters or fewer.',
      );
      return;
    }
    if (!spoken) _stopVoice();
    _inputFocus.unfocus();
    _input.clear();
    setState(() {
      _pending = question;
      _error = null;
    });
    _scrollToLatest();
    try {
      final reply = await widget.api.send(
        sessionId: _sessionId,
        message: question,
      );
      if (!mounted) return;
      final key = GlobalKey();
      setState(() {
        _turns.add((question, reply, key));
        _pending = null;
      });
      _scrollToLatest(key: reply is WardPlan ? key : null);
      if (spoken && _handsFree) unawaited(_readSpokenReply(reply));

      if (ModalRoute.isCurrentOf(context) != true) return;
      switch (reply) {
        case OpenDocument(:final document):
          unawaited(
            Navigator.pushNamed(context, '/document', arguments: document),
          );
        case OpenService(:final route, :final draft):
          unawaited(Navigator.pushNamed(context, route, arguments: draft));
        case WardQuestion() || WardPlan() || AdviceMessage():
          break;
      }
    } on AssistantFailure catch (failure) {
      if (!mounted) return;
      _input.text = question;
      setState(() {
        _pending = null;
        _error = failure.message;
      });
    }
  }

  Future<void> _readSpokenReply(AssistantReply reply) async {
    final sequence = _voiceSequence;
    final played = await _speak(reply);
    if (mounted &&
        played &&
        _voiceSequence == sequence &&
        reply is WardQuestion) {
      _startListening();
    }
  }

  Future<bool> _speak(AssistantReply reply, {bool manual = false}) async {
    final text = switch (reply) {
      WardPlan() => [
        reply.service,
        reply.message,
        for (final step in reply.steps) step.instruction,
      ].join(' '),
      _ => reply.message,
    };
    final played = await widget.voice.speakNepali(text);
    if (mounted && !played && manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A Nepali voice is unavailable on this device.'),
        ),
      );
    }
    return played;
  }

  Widget _chip(String label, String message) => ActionChip(
    label: Text(label),
    onPressed: _pending == null ? () => _send(message) : null,
    backgroundColor: CivicColors.surface,
    side: const BorderSide(color: CivicColors.border),
  );

  Widget _suggestions() => Wrap(
    spacing: 8,
    runSpacing: 4,
    children: [
      _chip('जन्म दर्ता', 'म जन्म दर्ताबारे जान्न चाहन्छु।'),
      _chip('विवाह दर्ता', 'म विवाह दर्ताबारे जान्न चाहन्छु।'),
      _chip('वडा सिफारिस', 'म वडा कार्यालयको सिफारिसबारे जान्न चाहन्छु।'),
    ],
  );

  Widget _questionBubble(String text) => Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: const EdgeInsets.only(left: 30, top: 12, bottom: 8),
      child: CivicPanel(color: CivicColors.blueLight, child: Text(text)),
    ),
  );

  Widget _speakButton(AssistantReply reply) => IconButton(
    tooltip: 'Read aloud in Nepali',
    color: CivicColors.navy,
    onPressed: () {
      _stopVoice();
      unawaited(_speak(reply, manual: true));
    },
    icon: const Icon(Icons.volume_up_outlined),
  );

  Widget _answer(AssistantReply reply, int index) {
    if (reply is WardPlan) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WardPlanPanel(key: ObjectKey(reply), plan: reply),
          Align(alignment: Alignment.centerRight, child: _speakButton(reply)),
        ],
      );
    }
    return CivicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(reply.message)),
              _speakButton(reply),
            ],
          ),
          if (reply is WardQuestion &&
              index == _turns.length - 1 &&
              reply.replies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final answer in reply.replies) _chip(answer, answer),
              ],
            ),
        ],
      ),
    );
  }

  Widget _composer() => DecoratedBox(
    decoration: const BoxDecoration(
      color: CivicColors.surface,
      border: Border(top: BorderSide(color: CivicColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: ListenableBuilder(
              listenable: widget.voice,
              builder: (context, _) {
                final voice = widget.voice;
                final feedback = _error ?? voice.error;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (feedback != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            feedback,
                            style: const TextStyle(color: CivicColors.red),
                          ),
                        ),
                      ),
                    if (voice.active)
                      _ListeningFeedback(
                        listening: voice.listening,
                        transcript: voice.transcript,
                        amplitude: voice.amplitude,
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            focusNode: _inputFocus,
                            enabled: _pending == null,
                            onSubmitted: _send,
                            textInputAction: TextInputAction.send,
                            maxLength: 1200,
                            decoration: const InputDecoration(
                              hintText: 'Type in Nepali or English',
                              counterText: '',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: voice.active
                              ? 'Cancel voice input'
                              : 'Speak in Nepali',
                          onPressed: _pending != null
                              ? null
                              : voice.active
                              ? _stopVoice
                              : _startListening,
                          color: CivicColors.navy,
                          icon: Icon(
                            voice.active
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none,
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Send question',
                          onPressed: _pending == null && !voice.active
                              ? () => _send(_input.text)
                              : null,
                          icon: const Icon(Icons.arrow_upward),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_isAiEntry ? nagarikAiName : 'Ward Office Helpdesk'),
      actions: [
        if (_turns.isNotEmpty)
          IconButton(
            tooltip: 'New conversation',
            onPressed: _pending == null ? _newConversation : null,
            icon: const Icon(Icons.add_comment_outlined),
          ),
      ],
    ),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: CivicScroll(
              controller: _scroll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isAiEntry)
                    const CivicPanel(
                      color: CivicColors.blueLight,
                      child: Row(
                        children: [
                          NagarikAiMark(size: 46),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Open a document, start a service, or ask a Ward Office question.',
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const ServiceHeading(
                      icon: Icons.account_balance_outlined,
                      title: 'वडा कार्यालय सहायता',
                      detail:
                          'Ask Nagarik AI about birth registration, marriage registration or ward recommendations.',
                    ),
                  if (_turns.isEmpty) ...[
                    const SizedBox(height: 12),
                    _suggestions(),
                  ],
                  for (final (index, turn) in _turns.indexed) ...[
                    _questionBubble(turn.$1),
                    KeyedSubtree(key: turn.$3, child: _answer(turn.$2, index)),
                  ],
                  if (_pending case final String question) ...[
                    _questionBubble(question),
                    const CivicPanel(
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Checking the reference…'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _composer(),
        ],
      ),
    ),
  );
}

class _ListeningFeedback extends StatelessWidget {
  const _ListeningFeedback({
    required this.listening,
    required this.transcript,
    required this.amplitude,
  });

  final bool listening;
  final String transcript;
  final double amplitude;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        NagarikAiListeningMark(listening: listening, amplitude: amplitude),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  listening ? 'Listening in Nepali…' : 'Opening microphone…',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (transcript.isNotEmpty)
                Text(
                  transcript,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 5),
              ExcludeSemantics(
                child: LinearProgressIndicator(
                  value: amplitude,
                  minHeight: 3,
                  backgroundColor: CivicColors.blueLight,
                  color: CivicColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
