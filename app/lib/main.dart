import 'package:flutter/material.dart';

import 'models/catalog.dart';
import 'models/service_draft.dart';
import 'screens/assistant_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/document_mockup_screen.dart';
import 'screens/husk_service_screen.dart';
import 'screens/service_request_screen.dart';
import 'services/assistant_api.dart';
import 'services/citizen_voice.dart';
import 'services/demo_activity.dart';
import 'theme.dart';
import 'widgets/civic_widgets.dart';

void main() => runApp(const NagarikSathi());

class NagarikSathi extends StatefulWidget {
  const NagarikSathi({super.key, this.api, this.voice});

  final AssistantApi? api;
  final CitizenVoice? voice;

  @override
  State<NagarikSathi> createState() => _NagarikSathiState();
}

class _NagarikSathiState extends State<NagarikSathi> {
  late final _api = widget.api ?? AssistantApi.configured();
  late final _voice = widget.voice ?? CitizenVoice();
  final _activity = DemoActivity();

  @override
  void dispose() {
    if (widget.api == null) _api.close();
    if (widget.voice == null) _voice.dispose();
    _activity.dispose();
    super.dispose();
  }

  Route<dynamic> _route(RouteSettings settings) {
    final args = settings.arguments;
    final draft = args is ServiceDraft ? args : const ServiceDraft();
    final page = switch (settings.name) {
      '/complaint' => ServiceRequestScreen(
        service: RequestService.complaint,
        activity: _activity,
        draft: draft,
      ),
      '/hib' => ServiceRequestScreen(
        service: RequestService.hib,
        activity: _activity,
        draft: draft,
      ),
      '/ward' => AssistantScreen(
        api: _api,
        voice: _voice,
        entry: AssistantEntry.wardOffice,
      ),
      '/assistant' => AssistantScreen(
        api: _api,
        voice: _voice,
        entry: AssistantEntry.nagarikAi,
      ),
      '/document' when args is CivicDocument => DocumentMockupScreen(
        document: args,
      ),
      '/social' when args is SocialService => HuskServiceScreen(service: args),
      _ => const CivicPage(
        title: 'Service unavailable',
        child: Text('Choose a service from Home.'),
      ),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Nagarik Sathi',
    debugShowCheckedModeBanner: false,
    theme: civicTheme(),
    themeMode: ThemeMode.light,
    home: DashboardScreen(activity: _activity),
    onGenerateRoute: _route,
  );
}
