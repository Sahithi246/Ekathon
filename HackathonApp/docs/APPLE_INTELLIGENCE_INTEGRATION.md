# Apple Intelligence integration for questionnaire Q&A

Use **Apple Intelligence** (Foundation Models) to answer questionnaire questions automatically from:

1. **Transcript** – e.g. from EkaScribe / voice recording  
2. **Backend data** – e.g. Patient Medical History, Other medical notes (like your screenshot)

No manual answering: the model reads transcript + backend data and fills suggestions for each question.

---

## Flow

```
Transcript (voice/EkaScribe) + Backend sections (API/backend)
                    ↓
         AppleIntelligenceQAService
                    ↓
         [AISuggestion] per question
                    ↓
         QuestionnaireViewModel(suggestions:)
                    ↓
         QuestionnaireScreen (user can “Insert” or edit)
```

---

## 1. What’s already in the app

- **`AppleIntelligenceQAService`**  
  - `generateSuggestions(transcript:backendSections:questions:) async -> [AISuggestion]`  
  - Builds one context string from transcript + `BackendMedicalSection` list.  
  - **With Apple Intelligence (iOS 18+):** intended to call Foundation Models (see below).  
  - **Without:** uses a fallback that derives answers from that same context (keyword/sentence matching). So the questionnaire still gets suggestions on all devices.

- **Models**  
  - `BackendMedicalSection` (title + items)  
  - `Question` (id, text, answerType, required)  
  - `AISuggestion` (questionId, suggestedAnswer, confidence, sourceText)

- **UI**  
  - `QuestionnaireViewModel(suggestions:)` and `QuestionnaireScreen` already show AI suggestions and “Insert”.

So: **you can already pass transcript + backend data into the service and get suggestions**, and the UI will show them. The only missing piece is calling the real Apple Intelligence API when available.

---

## 2. Enabling real Apple Intelligence (Foundation Models)

Requirements:

- **iOS 18+** (or the OS version that ships Foundation Models; check latest docs).  
- Device that **supports and has Apple Intelligence enabled**.  
- Add the **Foundation Models** framework to your app (see Apple’s docs / Xcode).

### Step 1: Add the framework

- In Xcode: target → **Frameworks, Libraries, and Embedded Content** → **+** → add **Foundation Models** (or the exact name from Apple’s SDK).  
- Or in **Package.swift** / SPM: add the system package if Apple exposes it that way (follow current Apple documentation).

### Step 2: Use the framework in the service

In `AppleIntelligenceQAService.swift`:

1. Add at the top:

   ```swift
   import FoundationModels
   ```

2. Replace the “stub” implementation of `generateWithFoundationModels` with real API calls. The exact API may look like one of these (check latest Apple docs):

   **Option A – Session-based**

   ```swift
   @available(iOS 18.0, *)
   private func generateWithFoundationModels(context: String, questions: [Question]) async -> [AISuggestion] {
       let session = LanguageModelSession()
       var suggestions: [AISuggestion] = []
       for question in questions {
           let prompt = buildPrompt(context: context, question: question)
           do {
               let response = try await session.respond(to: prompt)
               if let suggestion = parseResponse(response, questionId: question.id) {
                   suggestions.append(suggestion)
               }
           } catch {
               // fallback or skip
           }
       }
       return suggestions
   }
   ```

   **Option B – SystemLanguageModel**

   ```swift
   let model = SystemLanguageModel.default
   let response = try await model.respond(to: prompt)
   ```

3. Keep **context size** in mind: Foundation Models often have a **limited context window** (e.g. 4096 tokens). If transcript + backend is large, you may need to:

   - Truncate or summarize the transcript, or  
   - Send a shorter “summary” block for each question, or  
   - Ask one question per call and pass only the most relevant part of the context.

4. **Structured output (optional):**  
   If the framework supports **guided generation** (e.g. `@Generable`), you can define a small struct (answer + sourceText + confidence) and have the model fill it so you don’t need to parse free text in `parseResponse`.

---

## 3. Wiring transcript + backend data into the questionnaire

Where you have the **transcript** and **backend sections** (e.g. after EkaScribe returns or after you load patient data):

1. Build backend sections the same shape as your screenshot, e.g.:

   ```swift
   let backendSections: [BackendMedicalSection] = [
       BackendMedicalSection(
           title: "Patient Medical History",
           items: ["Personal History: Last menstrual period was approximately four months ago"]
       ),
       BackendMedicalSection(
           title: "Other medical notes",
           items: [
               "Patient's name is Sahiti",
               "Patient is currently pregnant",
               "Patient has not registered at a health center for pregnancy care",
               "Patient has not received TT (Tetanus Toxoid) injections",
               "Patient has an Aadhaar card",
               "Patient does not have any government benefits (JSY, JSSK)",
               "There are four members in the patient's household"
           ]
       )
   ]
   ```

2. Call the service and create the view model:

   ```swift
   let service = AppleIntelligenceQAService()
   let suggestions = await service.generateSuggestions(
       transcript: transcriptFromEkaScribe,
       backendSections: backendSections,
       questions: questions
   )
   let viewModel = QuestionnaireViewModel(suggestions: suggestions)
   ```

3. Show the questionnaire with that view model (e.g. pass `viewModel` into `QuestionnaireScreen` or equivalent).

Then:

- **With Apple Intelligence:** once you implement `generateWithFoundationModels` as above, those suggestions will come from the on-device model.  
- **Without:** the existing fallback still fills suggestions from the same transcript + backend context, so the flow works everywhere.

---

## 4. Summary

| Piece                         | Status |
|------------------------------|--------|
| Context from transcript + backend | Done in `AppleIntelligenceQAService` |
| Fallback (no Apple Intelligence)  | Done (keyword/sentence matching) |
| Questionnaire UI + ViewModel      | Done (suggestions + Insert) |
| Real Apple Intelligence           | Add Foundation Models and implement `generateWithFoundationModels` as above |

So: **yes, you can use Apple Intelligence to answer all questionnaire questions from transcript + backend data without manually answering.** The app is structured so you only need to add the Foundation Models dependency and the real `respond(to:)` (or equivalent) call in `AppleIntelligenceQAService` to switch from fallback to Apple Intelligence on supported devices.
