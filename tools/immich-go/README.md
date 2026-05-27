# immich-go (bulk import)

[immich-go](https://github.com/simulot/immich-go) is AGPL-3.0. It is **not** committed to this repo.

## Windows installer

Setup downloads `immich-go.exe` (pinned version) into this folder on first install.

## Manual install

1. Open https://github.com/simulot/immich-go/releases  
2. Download `immich-go_*_windows_amd64.zip` for the version in `.env.example` / installer config.  
3. Extract `immich-go.exe` here.

## Example

From the **project root** (Immich on :2283 with optimizer):

```powershell
.\tools\immich-go\immich-go.exe upload from-folder `
  --server="http://localhost:2283" `
  --api-key="YOUR_API_KEY" `
  --concurrent-tasks=2 `
  --client-timeout=60m `
  --on-errors=continue `
  --pause-immich-jobs=true `
  "D:\path\to\photos"
```

API key: Immich → Account Settings → API Keys.

More: [docs/RECIPES.md](../../docs/RECIPES.md#immich-go-bulk-upload)
