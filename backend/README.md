# Gamman AI Proxy (Vercel)

This folder contains a minimal backend proxy for the iOS app.

## Routes exposed to the app

- `POST /v1/anthropic/messages`
- `POST /v1/exa/search`
- `POST /v1/openai/images/generations` (optional)

## 1) Create a Vercel project

1. In Vercel, import this GitHub repository.
2. Set **Root Directory** to `backend`.
3. Keep framework preset as `Other`.

## 2) Add environment variables in Vercel

- `ANTHROPIC_API_KEY` (required)
- `EXA_API_KEY` (required for Exa resources)
- `OPENAI_API_KEY` (optional for images)
- `GAMMAN_AI_PROXY_CLIENT_TOKEN` (optional, recommended)

## 3) Deploy

Deploy from Vercel UI (or CLI). Vercel will pick up `vercel.json` in this folder.

## 4) Configure iOS app

In `Config/LocalSecrets.xcconfig`:

```xcconfig
GAMMAN_AI_PROXY_BASE_URL = https:$(SLASH)$(SLASH)your-vercel-domain.vercel.app
GAMMAN_AI_PROXY_CLIENT_TOKEN = your-token-if-set
```

For release builds, set production value in `Config/Release.xcconfig` or your CI secrets.

## Security notes

- Do not commit `.env` with real keys.
- App users should never receive vendor API keys.
- The optional client token is an extra gate, not a full auth system.
