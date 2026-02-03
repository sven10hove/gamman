const JSON_HEADER = { "content-type": "application/json; charset=utf-8" };

function sendJson(res, status, payload) {
  res.status(status).setHeader("content-type", JSON_HEADER["content-type"]);
  res.send(JSON.stringify(payload));
}

function parseBody(req) {
  if (req.body == null) return null;
  if (typeof req.body === "string") {
    try {
      return JSON.parse(req.body);
    } catch {
      return null;
    }
  }
  if (typeof req.body === "object") return req.body;
  return null;
}

function ensurePost(req, res) {
  if (req.method === "POST") return true;
  res.setHeader("allow", "POST");
  sendJson(res, 405, { error: "Method Not Allowed" });
  return false;
}

function authorizeClient(req, res) {
  const expected = process.env.GAMMAN_AI_PROXY_CLIENT_TOKEN;
  if (!expected) return true;

  const provided = req.headers["x-gamman-client-token"];
  if (typeof provided === "string" && provided === expected) return true;

  sendJson(res, 401, { error: "Unauthorized" });
  return false;
}

async function forwardJsonRequest({
  url,
  upstreamHeaders,
  body,
  timeoutMs = 60000
}) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        ...upstreamHeaders
      },
      body: JSON.stringify(body),
      signal: controller.signal
    });

    const text = await response.text();
    return { status: response.status, text };
  } finally {
    clearTimeout(timeoutId);
  }
}

function relayJsonResponse(res, upstream) {
  res.status(upstream.status);
  res.setHeader("content-type", JSON_HEADER["content-type"]);
  res.send(upstream.text);
}

module.exports = {
  authorizeClient,
  ensurePost,
  forwardJsonRequest,
  parseBody,
  relayJsonResponse,
  sendJson
};
