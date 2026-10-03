# puneknot.com

The website for Pune Knowledge on Tap (KnOT). A static site: `build.py` turns the files
here into HTML in `_site/`, which is published to Opalstack on every push to `main`
(see `deploy/opalcc/README.md`).

## Add a talk

You can do all of this in the GitHub web interface.

1. Upload the poster to `static/posters/`, named by date: `2026-11-26.jpg`.
   Portrait, about 1000 px wide.
2. Create `talks/2026-11-26-short-title.md` by copying the most recent file in `talks/`
   and changing it:

   ```
   ---
   title: Short Title
   subtitle: Optional second line
   speakers:
   - Speaker Name
   date: '2026-11-26'
   field: Geology
   poster: 2026-11-26.jpg
   ---

   The abstract, in plain paragraphs.

   ## About the speaker

   The bio.
   ```

3. Commit. The site rebuilds in a minute or two.

A talk dated today or later is shown as "Next on tap" on the home page, without a ticket
link: the WhatsApp community gets the link first. When registration opens to the public,
add one line to the talk's front matter and commit:

```
tickets_url: https://...
```

The day after the talk it moves into the archive by itself. Leave `tickets_url` in; it is
ignored for past talks.

Only put on the site what has already been announced publicly. Do not add speaker slides
or audience photographs without the permission of the people concerned.

## Change the words

- `pages/*.md`: How it works, The community, For speakers, About.
- `site.yaml`: venue, WhatsApp link, the evening's schedule, organizers, press links.
- `templates/home.html`: the home page.

## Build it on your own machine

```
pip install -r requirements.txt
python build.py
python -m http.server --directory _site 8000
```

## Layout

| Path | What |
|---|---|
| `talks/` | One Markdown file per talk |
| `pages/` | The long-form pages |
| `site.yaml` | Facts used across the site |
| `templates/` | Jinja2 HTML templates |
| `static/` | CSS, logo, posters |
| `build.py` | The generator |
| `deploy/opalcc/` | Deploy script and instructions for Opalstack |
| `.github/workflows/deploy.yml` | Runs the build and the deploy script |
