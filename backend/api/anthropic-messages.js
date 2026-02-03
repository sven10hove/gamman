const {
  authorizeClient,
  ensurePost,
  forwardJsonRequest,
  parseBody,
  relayJsonResponse,
  sendJson
} = require("./_shared");

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

module.exports = async (req, res) => {
  if (!ensurePost(req, res) || !authorizeClient(req, res)) return;

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    sendJson(res, 500, { error: "Server missing ANTHROPIC_API_KEY" });
    return;
  }

  const body = parseBody(req);
  if (!body) {
    sendJson(res, 400, { error: "Invalid JSON body" });
    return;
  }

  try {
    const upstream = await forwardJsonRequest({
      url: ANTHROPIC_URL,
      upstreamHeaders: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01"
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
