# The box side of mix.raakode.dk

Caddy serves `/opt/mix.raakode.dk/public` as a plain file server. Two things
share that directory and must not be disturbed: the Doctorow podcast mp3s and
`feed.xml`, whose URLs are published in the feed.

- `update.sh` — fast-forwards `/opt/mix.raakode.dk/repo` (a shallow clone of
  this repo) and copies `site/index.html` and every `tracks/<name>/latest.mp3`
  into the web root. It only ever copies; it never deletes.
- `pull-service.py` — runs `update.sh` and returns its output. It binds the
  docker gateway (172.17.0.1:8765) only, so it is not reachable from the
  internet; Caddy proxies `mix.raakode.dk/api/pull` to it.
- `mix-pull.service` — the systemd unit for the above.

The Caddyfile block holds the password (`basic_auth`, user `niels`), so the
page stays public while the button does not. The button only works for commits
that have been **pushed** — it fast-forwards from GitHub, not from your laptop.
Publishing straight from the laptop instead: `tools/deploy-mix.sh`.
