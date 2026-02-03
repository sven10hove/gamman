const {
  authorizeClient,
  ensurePost,
  forwardJsonRequest,
  parseBody,
  relayJsonResponse,
  sendJson
} = require("./_shared");

const EXA_URL = "https://api.exa.ai/search";

module.exports = async (req, res) => {
  if (!ensurePost(req, res) || !authorizeClient(req, res)) return;

  const apiKey = process.env.EXA_API_KEY;
  if (!apiKey) {
    sendJson(res, 500, { error: "Server missing EXA_API_KEY" });
    return;
  }

  const body = parseBody(req);
  if (!body) {
    sendJson(res, 400, { error: "Invalid JSON body" });
    return;
  }

  try {
    const upstream = await forwardJsonRequest({
      url: EXA_URL,
      upstreamHeaders: {
        "x-api-key": apiKey
      },
      body,
      timeoutMs: 30000
    });

    relayJsonResponse(res, upstream);
  } catch (error) {
    const isTimeout = error && error.name === "AbortError";
    sendJson(res, isTimeout ? 504 : 502, {
      error: isTimeout ? "Upstream timeout" : "Upstream request failed"
    });
  }
};
