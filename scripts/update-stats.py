#!/usr/bin/env python3
"""Rewrite the Retromod figures in the built site from the live APIs.

The page also refreshes these in the browser, but that call can be rate limited
or blocked, so the numbers baked into the HTML need to be current too.

Usage: update-stats.py <html-file>
"""
import json
import re
import sys
import urllib.error
import urllib.request

SOURCES = {
    "https://api.modrinth.com/v2/project/retromod": {
        "downloads": "downloads",
        "followers": "followers",
    },
    "https://api.github.com/repos/Bownlux/Retromod": {
        "stars": "stargazers_count",
    },
}


def fetch(url):
    req = urllib.request.Request(
        url, headers={"Accept": "application/json", "User-Agent": "bownlux.dev-build"}
    )
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.load(r)


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: update-stats.py <html-file>")
    path = sys.argv[1]
    html = open(path, encoding="utf-8").read()

    values = {}
    for url, wanted in SOURCES.items():
        try:
            data = fetch(url)
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
            # Keep whatever is already in the file rather than failing the build.
            print(f"warning: {url} unavailable ({e}), keeping existing numbers")
            continue
        for key, field in wanted.items():
            v = data.get(field)
            if isinstance(v, int):
                values[key] = v

    for key, value in values.items():
        pattern = re.compile(
            r'(<span class="fig" data-stat="%s">)[^<]*(</span>)' % re.escape(key)
        )
        html, n = pattern.subn(lambda m: m.group(1) + f"{value:,}" + m.group(2), html)
        if n:
            print(f"{key} = {value:,}")
        else:
            print(f"warning: no placeholder found for {key}")

    open(path, "w", encoding="utf-8").write(html)


if __name__ == "__main__":
    main()
