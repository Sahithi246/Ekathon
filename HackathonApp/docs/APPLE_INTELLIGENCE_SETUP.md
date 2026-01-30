# Apple Intelligence (Foundation Models) — Setup

The app uses **Apple Intelligence** to answer questionnaire questions from transcript + backend patient data. Everything is implemented; you only need to enable the framework in Xcode when building with iOS 26+.

---

## What’s implemented

1. **`AppleIntelligenceQAService`** – Builds context from transcript + backend sections and returns `[AISuggestion]`. On **iOS 26+** with Foundation Models available, it uses the on-device model; otherwise it uses a rule-based fallback.
2. **`FoundationModelsQARunner`** – Calls `LanguageModelSession`, `prewarm()`, and `respond(to:)` when `FoundationModels` is imported. Wrapped in `#if canImport(FoundationModels)` so the app still builds on older SDKs.
3. **`QuestionnaireScreen`** – Takes `questions`, `transcript`, and `backendSections`. On appear it calls the service and fills suggestions (Apple Intelligence or fallback).
4. **Sample data** – `QuestionnaireSampleData` provides default questions and backend sections (Patient Medical History / Other medical notes). `ContentView` passes them into the questionnaire so suggestions are generated on launch.

---

## Enabling Apple Intelligence (Xcode 26 / iOS 26)

1. **Xcode & SDK**  
   Use **Xcode 26** (or later) and the **iOS 26 SDK** so the Foundation Models framework is available.

2. **Link the framework**  
   - Select your app target → **General** → **Frameworks, Libraries, and Embedded Content**.  
   - Click **+** → choose **FoundationModels.framework** (under Apple frameworks).  
   - Leave embedding as **Do Not Embed**.

3. **Capability (if required)**  
   - Select your app target → **Signing & Capabilities**.  
   - If you see **Foundation Models** or **Apple Intelligence**, add it.  
   - If you only see **Foundation Model Adapter** (for custom adapters), you don’t need it for basic Q&A.

4. **Run on a supported device**  
   Apple Intelligence requires a supported device (e.g. iPhone 16+, M-series iPads/Macs). On older devices or simulators without support, the app uses the **fallback** (rule-based suggestions from the same context).

---

## Flow

- **ContentView** shows **QuestionnaireScreen** with:
  - `QuestionnaireSampleData.defaultQuestions`
  - `QuestionnaireSampleData.sampleTranscript`
  - `QuestionnaireSampleData.sampleBackendSections`
- **QuestionnaireScreen** runs a `.task` that calls **AppleIntelligenceQAService.generateSuggestions(...)**.
- On **iOS 26+** with Foundation Models linked, the service uses **FoundationModelsQARunner** (LanguageModelSession → respond → parse).
- Otherwise it uses **generateWithFallback** (keyword/sentence matching).
- Suggestions are applied to **QuestionnaireViewModel**; the user sees “AI Suggestion” and “Insert” for each question.

---

## Response type

`FoundationModelsQARunner` uses `response.content` after `session.respond(to: prompt)`. If the API returns a different type (e.g. `String` or a property with another name), update the line that reads the response text in `FoundationModelsQARunner.swift` to match the current Foundation Models API.

---

## Summary

| Piece | Status |
|-------|--------|
| Context from transcript + backend | Done |
| Fallback (no Apple Intelligence) | Done |
| Foundation Models integration (iOS 26) | Done (conditional on `#if canImport(FoundationModels)`) |
| Questionnaire UI + sample data | Done |
| Xcode: link Foundation Models | You add the framework when using Xcode 26 / iOS 26 |

Once the framework is linked and you run on a supported device, questionnaire suggestions are powered by Apple Intelligence; on other configurations, the same UI runs with the fallback.
