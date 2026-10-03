# Deploying to Opalstack (opalcc)

The site is static. `build.py` writes `_site/`, and `deploy.sh` copies that directory to
the document root of an Opalstack static app.

| | |
|---|---|
| Account | `navincc` on `opal2.opalstack.com` (SSH alias `opalcc` on Navin's laptop) |
| App | `puneknot`, type "Nginx Static Only" |
| Document root | `/home/navincc/apps/puneknot` |
| Site | `puneknot.com` and `www.puneknot.com`, routed to the app at `/` |

## One-time setup (Opalstack panel, done by hand)

1. Applications → Create: name `puneknot`, type **Nginx Static Only**.
2. Domains → add `puneknot.com` and `www.puneknot.com`.
3. Sites → Create: name `puneknot`, both domains, route `/` to the `puneknot` app,
   Let's Encrypt certificate on, redirect HTTP to HTTPS.
4. DNS at the registrar: either use Opalstack's nameservers, or point `A` records for
   `puneknot.com` and `www` at the IP the panel shows for the site.

Then, from the laptop, `deploy/opalcc/deploy.sh --dry-run` followed by
`SKIP_HEALTH=1 deploy/opalcc/deploy.sh` if DNS is not live yet.

## Normal deploy

Automatic: every push to `main`, and once a night, GitHub Actions runs
`.github/workflows/deploy.yml`, which calls `deploy/opalcc/deploy.sh`.

By hand, from the repository root on a machine with the `opalcc` SSH alias:

```
deploy/opalcc/deploy.sh --dry-run   # shows what would change
deploy/opalcc/deploy.sh
```

The script builds, checks the build, uploads with `rsync --delete --delay-updates`, and
finishes by requesting `https://puneknot.com/talks/`.

## Switching on the automatic deploy

Until this is done the workflow only builds, as a check.

1. Create an SSH key used for nothing else: `ssh-keygen -t ed25519 -f puneknot_deploy -N ""`.
2. Install the public key for an Opalstack shell user that can write to the app. Prefer a
   separate shell user limited to this app over the main `navincc` login; if one is used,
   change `OPALCC_SSH` in the workflow and `REMOTE_ROOT` in `deploy.sh` to match.
3. GitHub → repository Settings → Secrets and variables → Actions:
   - secret `OPALCC_SSH_KEY`: the private key;
   - variable `OPALCC_DEPLOY`: `true`;
   - variable `SKIP_HEALTH`: `1` only while DNS is not pointing at Opalstack; delete it after.
4. Delete the local copy of the private key.

`deploy/opalcc/known_hosts` pins the server's host keys. If Opalstack rotates them the
deploy fails at the SSH step; check the new keys with Opalstack before updating the file.

## What lives where

| State | Source of truth | Deploy action | Rule |
|---|---|---|---|
| Talks, pages, templates, posters | Git (`main`) | rebuilt every deploy | edit in the repository only |
| `_site/` | `build.py` output | replaces the document root | never edit on the server |
| Document root on Opalstack | the last deploy | fully overwritten, extra files deleted | keep nothing else there |
| Deploy key | GitHub secret `OPALCC_SSH_KEY` | not in the repository | rotate by repeating "Switching on" |

There is no database, no uploads and no server-side code, so there is nothing to back up
on the server: the repository is the backup.

## Checks, logs, rollback

- Health check: `curl -sI https://puneknot.com/talks/` should return 200.
- Logs: `ssh opalcc 'tail -50 ~/logs/apps/puneknot/access.log'` (and `error.log`).
- Rollback: `git revert <bad commit>` and push; or, by hand,
  `git checkout <good commit> && deploy/opalcc/deploy.sh && git checkout main`.
