# Deploying to Opalstack (opalcc)

The code lives on GitHub; the site is served from Opalstack. The server keeps its own
checkout of this repository. Every ten minutes a cron job there fetches `main`; if there
is a new commit (or the date has changed) it rebuilds the site and copies the result into
the static app's document root. The repository is public, so the server needs no
credentials for GitHub, and GitHub holds no credentials for the server.

| | |
|---|---|
| Account | `navincc` on `opal2.opalstack.com` (SSH alias `opalcc` on Navin's laptop) |
| App | `puneknot`, type "Nginx Static Only" |
| Document root | `/home/navincc/apps/puneknot` |
| Checkout | `/home/navincc/puneknot-src` |
| Site | `puneknot.com` and `www.puneknot.com`, routed to the app at `/` |

## One-time setup

In the Opalstack panel, by hand:

1. Applications → Create: name `puneknot`, type **Nginx Static Only**.
2. Domains → add `puneknot.com` and `www.puneknot.com`.
3. Sites → Create: name `puneknot`, both domains, route `/` to the `puneknot` app,
   Let's Encrypt certificate on, redirect HTTP to HTTPS.
4. DNS: the domain is registered at Namecheap and uses Opalstack's nameservers. In
   Namecheap → Domain List → Manage → Nameservers, choose "Custom DNS" and enter
   `ns1.sg.opalstack.com`, `ns2.sg.opalstack.com` and `ns3.sg.opalstack.com` (the server is in Singapore; the `.us` and `.de` sets serve the same records). Do this after step 2, so that Opalstack
   already has DNS records for the domain. Namecheap's own DNS records and email
   forwarding stop applying once the nameservers change.

Then on the server (`ssh opalcc`):

```
git clone https://github.com/ngkabra/puneknot.git ~/puneknot-src
~/puneknot-src/deploy/opalcc/setup.sh
```

`setup.sh` creates a Python 3.12 virtualenv in the checkout, adds the cron entry, and
publishes the site once. It does not need DNS to be live.

## Normal deploy

Push to `main`. The site updates within ten minutes.

To publish immediately, from the laptop:

```
ssh opalcc '~/puneknot-src/deploy/opalcc/update.sh --force'
```

`update.sh` fetches `main`, installs any new requirements, builds, checks the build, and
only then replaces the live files. If the build or the check fails, the live site is left
as it was and the failure is written to the log.

The GitHub Actions workflow (`.github/workflows/build-check.yml`) does not deploy. It only
checks that a push still builds, so a broken edit shows up as a red cross on GitHub.

## What lives where

| State | Source of truth | Deploy action | Rule |
|---|---|---|---|
| Talks, pages, templates, posters | GitHub (`main`) | pulled and rebuilt | edit in the repository only |
| Server checkout `~/puneknot-src` | GitHub | `git reset --hard origin/main` | edits made on the server are discarded |
| Document root `~/apps/puneknot` | the last build | fully overwritten, extra files deleted | keep nothing else there |
| `~/puneknot-src/.venv`, `.deploy/` | the server | kept | virtualenv, lock, stamp and log |

There is no database, no uploads, no server-side code and no secret, so there is nothing
to back up on the server: the repository is the backup.

## Checks, logs, rollback

- Health check: `curl -sI https://puneknot.com/talks/` should return 200.
- What is live: `ssh opalcc 'tail -5 ~/puneknot-src/.deploy/deploy.log'` shows the last
  published commit, or the build error if one failed.
- Web server logs: `ssh opalcc 'tail -50 ~/logs/apps/puneknot/access.log'` (and `error.log`).
- Rollback: `git revert <bad commit>` and push; the server picks it up like any other commit.
- Stop automatic updates: `ssh opalcc 'crontab -e'` and remove the `update.sh` line.
