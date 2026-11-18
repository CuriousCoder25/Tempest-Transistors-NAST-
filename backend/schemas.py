from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, StringConstraints, TypeAdapter, model_validator

Text = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=1200)]
ShortText = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=240)]
DocumentId = Literal["national_id", "driving_license", "pan", "citizenship", "passport", "voter_id"]
HibTab = Literal["status", "renewal", "enrollment"]
WardService = Literal["birth_registration", "marriage_registration", "ward_recommendation"]


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class AssistantRequest(StrictModel):
    session_id: UUID
    message: Text


class ShowDocument(StrictModel):
    action: Literal["SHOW_DOCUMENT"]
    document_id: DocumentId
    message_nepali: ShortText


class ComplaintFields(StrictModel):
    category: ShortText | None = None
    ward_number: ShortText | None = None
    description: Text | None = None


class HibFields(StrictModel):
    policy_id: ShortText | None = None
    district: ShortText | None = None
    family_details: Text | None = None


class ComplaintExplanations(StrictModel):
    category: ShortText
    ward_number: ShortText
    description: ShortText


class HibExplanations(StrictModel):
    policy_id: ShortText
    district: ShortText
    family_details: ShortText


class ComplaintNavigation(StrictModel):
    action: Literal["IN_APP_DEEP_NAV"]
    route: Literal["/complaint"]
    prefill_fields: ComplaintFields
    field_explanations_nepali: ComplaintExplanations
    message_nepali: ShortText


class HibNavigation(StrictModel):
    action: Literal["IN_APP_DEEP_NAV"]
    route: Literal["/hib"]
    tab: HibTab
    prefill_fields: HibFields
    field_explanations_nepali: HibExplanations
    message_nepali: ShortText


class Citation(StrictModel):
    page: int = Field(ge=1)
    excerpt: Text


class WardClarification(StrictModel):
    action: Literal["WARD_OFFICE_GUIDANCE"]
    coverage: Literal["verified"]
    ward_service: WardService
    needs_clarification: Literal[True]
    follow_up_question_nepali: ShortText
    quick_replies_nepali: list[ShortText] = Field(max_length=5)
    source: Citation


class ChecklistItem(StrictModel):
    label_nepali: ShortText
    status: Literal["have", "missing"]
    source: Citation


class WardStep(StrictModel):
    instruction_nepali: ShortText
    source: Citation
    fee_nepali: ShortText | None = None
    fee_source: Citation | None = None
    timeline_nepali: ShortText | None = None
    timeline_source: Citation | None = None

    @model_validator(mode="after")
    def verify_sources(self):
        if bool(self.fee_nepali) != bool(self.fee_source):
            raise ValueError("Fee text and source must be supplied together")
        if bool(self.timeline_nepali) != bool(self.timeline_source):
            raise ValueError("Timeline text and source must be supplied together")
        return self


class WardRoadmap(StrictModel):
    action: Literal["WARD_OFFICE_GUIDANCE"]
    coverage: Literal["verified"]
    ward_service: WardService
    needs_clarification: Literal[False]
    service_nepali: ShortText
    message_nepali: ShortText
    customized_checklist: list[ChecklistItem] = Field(min_length=1, max_length=16)
    step_by_step_map: list[WardStep] = Field(min_length=1, max_length=12)


class WardOutOfScope(StrictModel):
    action: Literal["WARD_OFFICE_GUIDANCE"]
    coverage: Literal["out_of_scope"]
    needs_clarification: Literal[False]
    message_nepali: ShortText


class HuskFeature(StrictModel):
    action: Literal["HUSK_FEATURE"]
    service: Literal["cit", "provident_fund", "ssf"]
    message_nepali: ShortText


AssistantResponse = (
    ShowDocument | ComplaintNavigation | HibNavigation | WardClarification
    | WardRoadmap | WardOutOfScope | HuskFeature
)
response_adapter = TypeAdapter(AssistantResponse)


def gemini_response_schema() -> dict:
    schema = response_adapter.json_schema()
    definitions = schema.pop("$defs")

    def convert(node):
        if isinstance(node, list):
            return [convert(item) for item in node]
        if not isinstance(node, dict):
            return node
        if "$ref" in node:
            return convert(definitions[node["$ref"].split("/")[-1]])
        if "const" in node:
            # Pydantic still enforces the literal boolean after generation.
            if isinstance(node["const"], bool):
                return {"type": "boolean"}
            return {"type": "string", "enum": [node["const"]]}
        return {
            key: convert(value)
            for key, value in node.items()
            if key not in {"title", "default", "minLength", "maxLength"}
        }

    return convert(schema)
