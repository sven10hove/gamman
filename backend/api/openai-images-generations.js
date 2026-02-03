const {
  authorizeClient,
  ensurePost,
  forwardJsonRequest,
  parseBody,
  relayJsonResponse,
  sendJson
} = require("./_shared");

const OPENAI_URL = "https://api.openai.com/v1/images/generations";

module.exports = async (req, res) => {
  if (!ensurePost(req, res) || !authorizeClient(req, res)) return;

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    sendJson(res, 503, { error: "OpenAI image generation not configured" });
    return;
  }

  const body = parseBody(req);
  if (!body) {
    sendJson(res, 400, { error: "Invalid JSON body" });
    return;
  }

  try {
    const upstream = await forwardJsonRequest({
      url: OPENAI_URL,
      upstreamHeaders: {
        authorization: `Bearer ${apiKey}`
      },
      body
    });

    relayJsonResponse(res, upstream);
  } catch (error) {
    const isTimeout = error && error.name === "AbortError";
    sendJson(res, isTimeout ? 504 : 502, {
      error: isTimeout ? "Upstream timeout" : "Upstream request failed"
    });
  }
};
