# AI Proxy Setup

Use this when you want users to stop entering vendor API keys and run all AI calls through your backend.

## 1) Keep vendor keys on the server

Store these in your backend `.env` (never in the iOS app bundle):

- `ANTHROPIC_API_KEY`
- `EXA_API_KEY` (optional)
- `OPENAI_API_KEY` (optional)

## 2) Expose proxy routes

Your backend should accept the same JSON payloads the app already sends and forward them to vendors:

- `POST /v1/anthropic/messages`
- `POST /v1/exa/search`
- `POST /v1/openai/images/generations`

Optional auth header from app:

- `x-gamman-client-token: <token>`

## 3) Configure the app (xcconfig, not `.env`)

This project now includes:

- `Config/Base.xcconfig`
- `Config/Debug.xcconfig`
- `Config/Release.xcconfig`
- `Config/LocalSecrets.xcconfig.example`

Setup:

1. Copy `Config/LocalSecrets.xcconfig.example` to `Config/LocalSecrets.xcconfig`.
2. Fill in your local debug values there.
3. Keep `Config/LocalSecrets.xcconfig` out of git (already ignored).

Note: in `.xcconfig`, use `https:$(SLASH)$(SLASH)api.yourdomain.com` (not raw `https://...`).

Release builds:

- Set production `GAMMAN_AI_PROXY_BASE_URL` in `Config/Release.xcconfig` (or via CI `xcodebuild` overrides).
- Do not put vendor keys in release app configs.

Supported keys:

- `GAMMAN_AI_PROXY_BASE_URL`
- `GAMMAN_AI_PROXY_CLIENT_TOKEN` (optional)

Optional fallback (not recommended for production):

- `GAMMAN_CLAUDE_API_KEY`
- `GAMMAN_EXA_API_KEY`
- `GAMMAN_OPENAI_API_KEY`

## 4) Security hardening (recommended)

- Rate-limit by IP/user/device.
- Require app authentication (session/JWT) instead of only a static token.
- Add abuse detection and per-user quotas.
- Log and monitor proxy usage.
