# puneknot.com

The website for Pune Knowledge on Tap (KnOT). A static site: `build.py` turns the files
here into HTML in `_site/`. The Opalstack server pulls `main` from GitHub every ten
minutes and rebuilds (see `deploy/opalcc/README.md`).

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
   category: Science & nature
   poster: 2026-11-26.jpg
   ---

   The abstract, in plain paragraphs.

   ## About the speaker

   The bio.
   ```

   To link a speaker's website or social media from the talk page, write the speaker as a
   small block instead of a plain name. Everything except `name` is optional:

   ```
   speakers:
   - name: Speaker Name
     url: https://their-website.example
     links:
       X: https://x.com/handle
       LinkedIn: https://www.linkedin.com/in/handle
       Email: mailto:someone@example.org
   ```

   `url` turns the name into a link; each line under `links` becomes a labelled link below it.
   Plain names and blocks can be mixed in one talk.

   `field` is free text. `category` drives the filter on the Talks page and must be one of the
   groups listed under `categories` in `site.yaml`.

3. Commit. The site updates within ten minutes.

A talk dated today or later is shown as "Next talk" on the home page. Add it as soon as the
talk is announced, **without** a ticket link: the WhatsApp community gets the link first, so
the button reads "Join the community for details" and points at the WhatsApp community.

If tickets have not sold out a few days before the talk, we promote it on social media. At
that point add the registration link to the talk's front matter and commit:

```
tickets_url: https://...
```

The button then reads "Get a ticket" and goes to the registration page, on the home page and
on the talk's own page.

The home page shows the speaker's photo next to the talk. Cut it out of the poster as a
square, about 400 px, save it as `static/speakers/2026-11-26.jpg` (the site rounds it into a
circle), and add:

```
speaker_photo: 2026-11-26.jpg
```

Without `speaker_photo`, the home page shows a small copy of the poster instead.

The home page has a countdown to the next talk. It runs to the date of the next talk file.
If there is none, it runs to `next_date` in `site.yaml` if you have set one, and otherwise to
the last Thursday of the month, shown as an "expected date". So when a date is fixed before
the speaker is announced, or the talk is not on the last Thursday, set `next_date`.

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
| `static/` | CSS, logo, posters, speaker photos |
| `build.py` | The generator |
| `deploy/opalcc/` | Scripts and instructions for the Opalstack server, which pulls from GitHub |
| `.github/workflows/build-check.yml` | Checks that a push still builds; does not deploy |
