import 'catalog.dart';
import 'service_draft.dart';

typedef Json = Map<String, dynamic>;

sealed class AssistantReply {
  const AssistantReply(this.message);

  final String message;

  factory AssistantReply.fromJson(Json json) {
    String message() => json['message_nepali'] as String;
    switch (json['action']) {
      case 'SHOW_DOCUMENT':
        return OpenDocument(
          message(),
          CivicDocument.values.firstWhere(
            (item) => item.id == json['document_id'],
          ),
        );
      case 'IN_APP_DEEP_NAV':
        final route = json['route'];
        if (route != '/complaint' && route != '/hib') {
          throw const FormatException('Unsupported service route');
        }
        return OpenService(
          message(),
          route as String,
          ServiceDraft(
            prefill: _strings(json['prefill_fields'] as Json),
            explanations: _strings(json['field_explanations_nepali'] as Json),
            hibTab: switch (json['tab']) {
              'renewal' => HibTab.renewal,
              'enrollment' => HibTab.enrollment,
              _ => HibTab.status,
            },
          ),
        );
      case 'WARD_OFFICE_GUIDANCE':
        if (json['coverage'] == 'out_of_scope') return AdviceMessage(message());
        if (json['needs_clarification'] == true) {
          return WardQuestion(
            json['follow_up_question_nepali'] as String,
            (json['quick_replies_nepali'] as List).cast<String>(),
          );
        }
        return WardPlan(
          message(),
          service: json['service_nepali'] as String,
          checklist: (json['customized_checklist'] as List)
              .map((value) => WardChecklistItem.fromJson(value as Json))
              .toList(),
          steps: (json['step_by_step_map'] as List)
              .map((value) => WardStep.fromJson(value as Json))
              .toList(),
        );
      case 'HUSK_FEATURE':
        return AdviceMessage(message());
      default:
        throw const FormatException('Unsupported assistant action');
    }
  }

  static Map<String, String> _strings(Json json) => {
    for (final entry in json.entries)
      if (entry.value case final String value) entry.key: value,
  };
}

final class OpenDocument extends AssistantReply {
  const OpenDocument(super.message, this.document);
  final CivicDocument document;
}

final class OpenService extends AssistantReply {
  const OpenService(super.message, this.route, this.draft);
  final String route;
  final ServiceDraft draft;
}

final class AdviceMessage extends AssistantReply {
  const AdviceMessage(super.message);
}

final class WardQuestion extends AssistantReply {
  const WardQuestion(super.message, this.replies);
  final List<String> replies;
}

final class WardPlan extends AssistantReply {
  const WardPlan(
    super.message, {
    required this.service,
    required this.checklist,
    required this.steps,
  });
  final String service;
  final List<WardChecklistItem> checklist;
  final List<WardStep> steps;
}

class WardChecklistItem {
  const WardChecklistItem(this.label, this.have, this.page);

  factory WardChecklistItem.fromJson(Json json) => WardChecklistItem(
    json['label_nepali'] as String,
    json['status'] == 'have',
    (json['source'] as Json)['page'] as int,
  );

  final String label;
  final bool have;
  final int page;
}

class WardStep {
  const WardStep(
    this.instruction,
    this.fee,
    this.timeline,
    this.page,
    this.feePage,
    this.timelinePage,
  );

  factory WardStep.fromJson(Json json) => WardStep(
    json['instruction_nepali'] as String,
    json['fee_nepali'] as String?,
    json['timeline_nepali'] as String?,
    (json['source'] as Json)['page'] as int,
    (json['fee_source'] as Json?)?['page'] as int?,
    (json['timeline_source'] as Json?)?['page'] as int?,
  );

  final String instruction;
  final String? fee;
  final String? timeline;
  final int page;
  final int? feePage;
  final int? timelinePage;
}
