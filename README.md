# PostureCoach-Flutter
Flutter app for PostureCoach posture monitor

## CPR Debriefing System: Separation of Concerns

### 1) Ingestion and synchronization
- **Purpose:** Gather and time-align raw inputs.
- **Modules:** SimMan parser, STT, and diarization each extract + timestamp events/utterances from exactly one source type.
- **Synchronizer:** Aligns all source streams into one unified event timeline.
- **Boundary:** No clinical analysis, scoring, or report-generation logic in this layer.

### 2) Analysis engines
- **Purpose:** Convert unified timeline data into structured findings using explicit logic.
- **Engine responsibilities:**
  - ACLS rule FSM: rule/protocol validation
  - NLP v1: communication/entity detection
  - Cross-stream verifier: evidence cross-correlation
- **Boundary:** No raw-source parsing/time alignment and no scoring/report formatting in this layer.

### 3) Scoring and synthesis
- **Purpose:** Turn findings into metrics and narrative output.
- **Scoring engine:** Aggregates findings into domain metrics with confidence.
- **Narrative synthesis:** Consumes only structured findings + metrics and generates constrained LLM report text.
- **Boundary:** No parsing or event-extraction logic in this layer.

### 4) Interface and flow contract
- Data flows **strictly layer-to-layer** through minimal, stable interfaces (for example: unified timeline, findings JSON, metrics).
- This separation supports:
  - **Maintainability:** each module is independently testable
  - **Extensibility:** engines/rubrics can be swapped with minimal coupling
  - **Safety and robustness:** clinical reasoning is isolated from data plumbing and from LLM creativity
