# Codex Provider

## Exact Quota

Codex quota is fetched with the existing Codex OAuth access token:

```text
GET https://chatgpt.com/backend-api/wham/usage
Authorization: Bearer <access_token>
ChatGPT-Account-Id: <account_id>
Accept: application/json
```

Credentials are read from:

```text
~/.codex/auth.json
$CODEX_HOME/auth.json
```

Expected response fields:

- `rate_limit.primary_window.used_percent`
- `rate_limit.primary_window.reset_at`
- `rate_limit.primary_window.limit_window_seconds`
- `rate_limit.secondary_window.used_percent`
- `rate_limit.secondary_window.reset_at`
- `rate_limit.secondary_window.limit_window_seconds`

The normalizer maps windows by `limit_window_seconds`, not by field order alone.

If the host network cannot reach the default endpoint, set `CODEX_USAGE_URL` to a full compatible `wham/usage` URL. This is intended for local or corporate proxy setups and still requires the exact Codex usage response shape.

## Token Refresh

If `last_refresh` is older than 8 days, refresh the OAuth token through:

```text
POST https://auth.openai.com/oauth/token
```

The OAuth client id is a public application identifier used by Codex-compatible flows. It is not a user secret.

The refresh request body is JSON:

```json
{
  "client_id": "app_EMoamEEZ73f0CkXaXp7hrann",
  "grant_type": "refresh_token",
  "refresh_token": "<refresh_token>",
  "scope": "openid profile email"
}
```

## Today's Token Usage

Today's local token count is scanned from Codex JSONL session files. This data source is separate from the quota API.

The scanner uses the last `payload.info.total_token_usage` record in each session file for the selected day. This avoids double-counting cumulative `token_count` rows in a single Codex session.

## Endpoint Risk

`wham/usage` is used by current open-source Codex usage tools but is not documented as a stable public API. Keep the endpoint isolated, test response decoding, and surface malformed responses clearly.
