# le4ds MCP

Plan, draft and schedule your social media posts from Claude.

**le4ds MCP** is the official [Model Context Protocol](https://modelcontextprotocol.io) server for
[le4ds.com](https://le4ds.com). Connect it to Claude Code, Claude Desktop, Cursor or any MCP client, and your
assistant can upload a video, write the caption for each network, create the post in your le4ds calendar and,
once you approve it, schedule it, with a different time per network if you want.

It is a **remote server**: there is nothing to install or host. You create an API key in le4ds and point your
client at `https://le4ds.com/mcp`.

```
You:    Here's the reel for Tuesday. Post it to Instagram and Facebook at 9:00,
        and to TikTok at 18:00. Write a caption for each one.
Claude: [uploads the video, creates a draft, shows you the plan]
        Here is the plan... Shall I schedule it?
You:    Go.
Claude: [schedules it] Done. It's in your le4ds calendar.
```

---

## Contents

- [How it works](#how-it-works)
- [Quick start](#quick-start)
- [Connecting your client](#connecting-your-client)
- [API keys and permissions](#api-keys-and-permissions)
- [Tools](#tools)
- [Typical workflows](#typical-workflows)
- [Uploading media](#uploading-media)
- [Agencies: Vault clients](#agencies-vault-clients)
- [Limits](#limits)
- [Security](#security)
- [FAQ](#faq)

---

## How it works

| | |
|---|---|
| **Endpoint** | `https://le4ds.com/mcp` |
| **Transport** | Streamable HTTP |
| **Authentication** | `Authorization: Bearer <your API key>` |
| **Networks** | Facebook, Instagram, YouTube, TikTok, LinkedIn (the accounts you connected in le4ds) |

**Drafts first, always.** `create_post` only ever creates a **draft**. Nothing is published or scheduled until
`schedule_post` is called, and the server instructs the assistant to show you the plan (text, networks, formats,
media, date and time) and to wait for your approval before it does that. You can also review every draft in the
le4ds calendar, where posts created through the MCP carry a **"via Claude"** badge.

The same rules as the le4ds app apply: format checks (for example, Reels and Stories must be vertical 9:16 video),
caption limits per network, TikTok publishing settings, the LinkedIn PDF carousel rules and your plan's limits.

## Quick start

1. Sign in to [le4ds.com](https://le4ds.com) and connect your social accounts.
2. Go to **Settings → API keys** and create a key. Copy it: it is shown only once.
3. Add the server to your client (below).
4. Ask: *"List my le4ds accounts."*

## Connecting your client

Replace `YOUR_API_KEY` with your key. Never commit it to a repository.

### Claude Code

```bash
claude mcp add --transport http le4ds https://le4ds.com/mcp \
  --header "Authorization: Bearer YOUR_API_KEY"
```

Check it with `claude mcp list`. Claude Code can also run the upload commands for you (see
[Uploading media](#uploading-media)), which makes it the best client for video workflows.

### Claude Desktop

Claude Desktop connects to remote servers through [`mcp-remote`](https://www.npmjs.com/package/mcp-remote)
(requires Node.js 18+). Add this to `claude_desktop_config.json`
(Settings → Developer → Edit config), then restart Claude Desktop:

```json
{
  "mcpServers": {
    "le4ds": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://le4ds.com/mcp",
        "--header",
        "Authorization:${LE4DS_AUTH}"
      ],
      "env": {
        "LE4DS_AUTH": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

The header is passed through an environment variable on purpose: some clients split arguments on spaces.

### Cursor

`~/.cursor/mcp.json` (or `.cursor/mcp.json` in a project):

```json
{
  "mcpServers": {
    "le4ds": {
      "url": "https://le4ds.com/mcp",
      "headers": {
        "Authorization": "Bearer YOUR_API_KEY"
      }
    }
  }
}
```

### Other clients

Any client that supports remote MCP servers over HTTP with a custom header works. Use the endpoint and the
`Authorization` header above. More examples in [`examples/`](examples).

> **claude.ai (web) custom connectors** require OAuth, which is not supported yet. It is on the roadmap.

## API keys and permissions

Create and revoke keys in **Settings → API keys**. Each key has a name, optional expiry (30, 90 or 365 days) and
one or more permissions:

| Permission | Allows |
|---|---|
| `posts:read` | List accounts, clients and posts; read a post's status |
| `posts:write` | Upload media, create drafts, delete drafts |
| `posts:schedule` | Schedule, reschedule and cancel posts |

New keys get all three by default. For a key that can prepare drafts but never schedule them, leave
`posts:schedule` unticked: you then schedule from the le4ds calendar yourself.

Up to 10 active keys per account. Revoking a key takes effect immediately.

## Tools

| Tool | Permission | What it does |
|---|---|---|
| `list_accounts` | `posts:read` | Your connected accounts, with platform, accepted formats and limits |
| `list_clients` | `posts:read` | Your Vault clients (Agency plan, see below) |
| `list_posts` | `posts:read` | Posts filtered by status and date range |
| `get_post` | `posts:read` | One post, with the status and any error per network |
| `request_video_upload` | `posts:write` | Starts a multipart video upload and returns presigned part URLs |
| `complete_video_upload` | `posts:write` | Completes the video upload and returns the media URL |
| `abort_video_upload` | `posts:write` | Cancels an unfinished video upload |
| `request_file_upload` | `posts:write` | Returns a presigned URL to upload an image or a PDF |
| `complete_file_upload` | `posts:write` | Confirms the image or PDF upload and returns the media URL |
| `create_post` | `posts:write` | Creates a **draft** post |
| `schedule_post` | `posts:schedule` | Schedules (or reschedules) a draft, optionally with a time per network |
| `cancel_post` | `posts:schedule` | Cancels a scheduled post |
| `delete_draft` | `posts:write` | Deletes a draft |

### Parameters

**`list_accounts`**
- `client_id` *(integer, optional)*: a Vault client's accounts. Omit for your own accounts.

**`list_posts`**
- `status` *(optional)*: `draft`, `scheduled`, `publishing`, `published`, `published_with_errors` or `failed`
- `from`, `to` *(optional, `YYYY-MM-DD`)*
- `client_id` *(integer, optional)*
- `limit` *(integer 1–50, default 20)*

**`get_post`**, **`cancel_post`**, **`delete_draft`**
- `post_id` *(integer, required)*

**`create_post`**
- `content` *(string, required, up to 5000 characters)*: the shared caption
- `platforms` *(array, required)*: any of `facebook`, `instagram`, `youtube`, `tiktok`, `linkedin`
- `social_account_ids` *(array of integers, required)*: from `list_accounts`
- `post_type` *(optional, default `feed`)*: `feed`, `story`, `reel` or `short`
- `target_formats` *(object, optional)*: format per account id, e.g. `{"12": "reel", "15": "feed"}`
- `content_overrides` *(object, optional)*: caption per platform, e.g. `{"linkedin": "…"}`
- `media_urls` *(array of https URLs, optional)*: URLs returned by the upload tools, or public https URLs
- `youtube_options`, `linkedin_options`, `tiktok_options` *(objects, optional)*: same options as in the app
  (e.g. YouTube title and privacy, LinkedIn PDF carousel `document_url`, TikTok privacy level per account)
- `client_id` *(integer, optional)*: create the post for a Vault client

Dates are ignored: a new post is always a draft.

**`schedule_post`**
- `post_id` *(integer, required)*
- `scheduled_at` *(ISO-8601 with offset, required)*: the default time, e.g. `2026-10-25T09:00:00+01:00`
- `target_schedules` *(object, optional)*: own time per account id, e.g. `{"15": "2026-10-25T18:00:00+01:00"}`

Always send dates with an explicit timezone offset. Times are stored in UTC.

**`request_video_upload`**
- `filename` *(string, required)*: `.mp4`, `.mov` or `.webm`
- `size` *(integer bytes, required)*

**`complete_video_upload`**
- `key`, `upload_id` *(required, from `request_video_upload`)*
- `parts` *(required)*: `[{ "part_number": 1, "etag": "\"…\"" }, …]`

**`abort_video_upload`**
- `key`, `upload_id` *(required)*

**`request_file_upload`**
- `filename` *(string, required)*, `size` *(integer bytes, required)*
- `kind` *(optional)*: `image` (default) or `pdf`

**`complete_file_upload`**
- `key` *(required)*, `kind` *(optional, `image` or `pdf`)*

## Typical workflows

**A vertical video as Reel + TikTok, different times**
1. `list_accounts` to get the account ids.
2. Upload the video (see below) and keep the returned URL.
3. `create_post` with the caption, `content_overrides` per network, `media_urls` and
   `target_formats` (`reel` for Instagram/Facebook, `feed` for TikTok).
4. Review the plan, approve it.
5. `schedule_post` with `scheduled_at` and a `target_schedules` entry for the TikTok account.

**A LinkedIn carousel from a PDF**
1. `request_file_upload` with `kind: "pdf"`, upload, `complete_file_upload`.
2. `create_post` for the LinkedIn account with `linkedin_options.document_url` set to the PDF URL.

**Check what went out this week**
- `list_posts` with `from`/`to`, then `get_post` for anything `failed` or `published_with_errors`.

Example prompts in [`examples/prompts.md`](examples/prompts.md).

## Uploading media

Media files are sent straight to storage with presigned URLs, never through the MCP call itself, so a 200 MB video
works fine. Your assistant needs to be able to run `curl` (Claude Code can), or you can run the scripts yourself.

**Video (multipart):** `request_video_upload` returns `key`, `upload_id`, `part_size` and a list of
`{part_number, url}`. Split the file into `part_size` chunks, `PUT` each chunk to its URL, collect the `ETag`
response header of each part, then call `complete_video_upload`. See
[`examples/upload-video.sh`](examples/upload-video.sh).

**Image or PDF (single PUT):** `request_file_upload` returns `url`, `method` (`PUT`) and `headers`. Upload the file
with those headers, then call `complete_file_upload`. See [`examples/upload-file.sh`](examples/upload-file.sh).

Presigned URLs expire after 15 minutes.

## Agencies: Vault clients

On the **Agency** plan (€30/month, VAT included) you manage clients' accounts in the le4ds Vault, and the MCP works on
them. There is no add-on to buy: Vault clients via MCP are part of the Agency plan.

Pass `client_id` (from `list_clients`) to `list_accounts`, `list_posts` and `create_post`. A post uses either your own
accounts or one client's accounts, never both. On the Free and Pro plans the MCP works on your own accounts only.

## Limits

- **Rate limit:** 60 requests per minute per API key.
- **Plan limits** (networks, accounts per network, clients) are the same as in the app.
- **Formats** follow the platforms' rules; for example Reels and Stories must be 9:16 video, and Story and Reel posts
  take exactly one media file.
- **Video upload:** up to 500 MB per file.

## Security

- Treat an API key like a password. Store it in your client's config or an environment variable, never in a
  repository or a shared chat.
- Give each tool or machine its own key, with only the permissions it needs, so you can revoke one without
  breaking the others.
- Revoke a key in **Settings → API keys** as soon as you suspect it leaked. The key list shows when each key was
  last used.
- Every request is scoped to the key's owner: a key can never see or change another account's data.

## FAQ

**Can the assistant publish without asking me?**
It can only create drafts. Scheduling needs `posts:schedule`, and the server tells the assistant to get your
approval first. If you want a hard guarantee, create a key without `posts:schedule`.

**Does it work with my timezone?**
Yes. The assistant sends times with your offset (e.g. `+01:00`); le4ds stores them in UTC and shows them in your
local time in the calendar.

**Which clients are supported?**
Claude Code, Claude Desktop (via `mcp-remote`), Cursor and any client that supports remote HTTP MCP servers with a
custom header. claude.ai web connectors (OAuth) are on the roadmap.

**Where do I report a problem?**
Open an issue in this repository or write to hello@le4ds.com.

---

Built by [DigitalDev](https://digitaldev.pt). Licensed under the [MIT License](LICENSE) (this repository's
documentation and examples; the le4ds service is subject to its [terms](https://le4ds.com/terms)).
