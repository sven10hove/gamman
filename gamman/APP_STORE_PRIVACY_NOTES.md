## App Store Privacy Notes (Draft)

### Data flows observed in code
- AI text generation: user prompts and journal summaries are sent to Anthropic (`https://api.anthropic.com/v1/messages`).
- Resource search: lesson section content and topic metadata are sent to Exa (`https://api.exa.ai/search`) when a key is provided.
- Image generation: section prompt metadata is sent to OpenAI Images (`https://api.openai.com/v1/images/generations`) when a key is provided, and the resulting image is downloaded from the returned URL.
- API keys are stored locally in Keychain; no account system is present.
- Journal entries are stored on device (SwiftData) and are included in AI prompts when insights are generated.

### Likely App Store privacy categories
- User Content: journal text, triggers, body locations, prompts sent to third-party AI services.
- Other Data: API keys entered by the user (stored on device in Keychain).

### Tracking
- No evidence of tracking, advertising, or analytics SDKs in the current code.
- No identifiers are transmitted for tracking purposes.

### Notes for the privacy questionnaire
- Data is linked to the user only in the sense that it is the user's own content; no account or external identifier is used.
- Data is transmitted to third-party processors only when the user initiates AI features.
- Consider disclosing third-party processors: Anthropic, Exa, OpenAI (Images).

### Verify before submission
- Confirm whether any analytics, crash reporting, or push notification services are added outside this repo.
- Confirm whether any HealthKit data is collected (currently only placeholders in the model).
