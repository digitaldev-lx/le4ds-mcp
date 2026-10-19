# Changelog

## 1.0.0 — 2026-10-19

First release of the le4ds remote MCP server (`https://le4ds.com/mcp`).

- API keys with `posts:read`, `posts:write` and `posts:schedule` permissions, managed in Settings → API keys.
- Tools: `list_accounts`, `list_clients`, `list_posts`, `get_post`, `request_video_upload`,
  `complete_video_upload`, `abort_video_upload`, `request_file_upload`, `complete_file_upload`, `create_post`,
  `schedule_post`, `cancel_post`, `delete_draft`.
- Drafts by default: `create_post` never schedules; `schedule_post` does, with optional time per network.
- Vault clients for agencies. Included in the Agency plan (€30/month); there is no separate add-on.
