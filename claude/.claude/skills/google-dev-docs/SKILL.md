---
name: google-dev-docs
description: |
  Searches Google's official developer documentation (Firebase, Google Cloud,
  Android, Maps, Gemini, ADK, Chrome, and more) for authoritative, up-to-date
  API references, code examples, guides, and best practices. Equivalent to the
  google-dev-knowledge MCP server. Use when writing code with Google products
  or services. Trigger on: Google Cloud/Firebase/Android questions,
  "google docs", GCP implementation questions, Google API usage.
user_invocable: true
argument: "<query> [--mode=answer|search]"
---

# Google Developer Documentation

Searches Google's official developer documentation via the Developer Knowledge API. Provides authoritative, up-to-date information from Google's public docs:
ADK, Android, Apigee, Chrome, Firebase, Gemini, Google AI, Google Cloud, Google Maps, and more.

## Workflow

### Mode A: Grounded Answer (default)

Get a direct AI-generated answer grounded in Google's docs:

```bash
python3 <skill_dir>/scripts/google_dev_api.py answer "<query>"
```

Returns: `answerText` (AI answer) + `references` (source document names).

### Mode B: Document Search

Find specific documentation snippets:

```bash
python3 <skill_dir>/scripts/google_dev_api.py search "<query>" --limit=5
```

Returns: `documentChunks[]` with `content`, `parent` (document name), and `title`.

### Mode C: Get Full Document

After finding a relevant document with `search`, fetch its full Markdown content:

```bash
python3 <skill_dir>/scripts/google_dev_api.py get "<parent_from_search>"
```

For multiple documents:

```bash
python3 <skill_dir>/scripts/google_dev_api.py get "<name1>" "<name2>" ...
```

## API Key Setup

1. Go to https://console.cloud.google.com/start/api?id=developerknowledge.googleapis.com
2. Select your Google Cloud project and click **Enable**
3. Go to https://console.cloud.google.com/apis/credentials → **Create credentials** → **API key**
4. Restrict the key to the *Developer Knowledge API* only
5. Set the environment variable:

```bash
export GOOGLE_DEVELOPER_KNOWLEDGE_API_KEY="YOUR_API_KEY"
```

## Example Usage

```
# Ask about BigQuery
google_dev_api.py answer "How do I create a BigQuery dataset?"

# Search for Firebase Cloud Messaging docs
google_dev_api.py search "Firebase Cloud Messaging push notifications Android"

# Get full document content
google_dev_api.py get "documents/firebase.google.com/docs/cloud-messaging/android/client"
```

## Notes

- `<skill_dir>` = this SKILL.md's parent directory
- Output language: Korean for summaries, English for code/docs
- `answer` mode has limited quota — use `search` + `get` for heavy usage
- Results are English-only (the API only supports English content)
- Covered products: ADK, Android, Apigee, Chrome, Firebase, Fuchsia, Gemini CLI, Go, Google AI, Antigravity, Google Cloud, Google Developers/Ads/Search/Maps/YouTube, Google Home, TensorFlow, Web
- If you get `429` errors from `answer`, fall back to `search` mode
