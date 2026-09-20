#!/usr/bin/python3
"""Generate the public ECZOS repository index and recovery catalog."""

import argparse
import gzip
import hashlib
import html
import json
import os
import shutil
import tempfile
from datetime import date
from pathlib import Path


def deb822_paragraphs(text):
    paragraphs = []
    current = {}
    key = None
    for line in text.splitlines() + [""]:
        if not line:
            if current:
                paragraphs.append(current)
                current, key = {}, None
            continue
        if line[0].isspace() and key:
            current[key] += "\n" + line[1:]
            continue
        key, separator, value = line.partition(":")
        if separator:
            current[key] = value.strip()
    return paragraphs


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def atomic_text(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(value)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def stage_image(source, destination):
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists() and source.stat().st_size == destination.stat().st_size:
        if sha256(source) == sha256(destination):
            return
    temporary = destination.with_name(f".{destination.name}.part")
    temporary.unlink(missing_ok=True)
    try:
        os.link(source, temporary)
    except OSError:
        shutil.copy2(source, temporary)
    os.chmod(temporary, 0o644)
    os.replace(temporary, destination)


def render_index(packages, releases):
    rows = []
    for package in sorted(packages, key=lambda item: item.get("Package", "")):
        filename = html.escape(package.get("Filename", ""), quote=True)
        name = html.escape(package.get("Package", ""))
        version = html.escape(package.get("Version", ""))
        architecture = html.escape(package.get("Architecture", ""))
        description = html.escape(package.get("Description", "").split("\n", 1)[0])
        rows.append(
            f'<tr><td><a href="{filename}">{name}</a></td><td>{version}</td>'
            f'<td>{architecture}</td><td>{description}</td></tr>')
    release_cards = []
    for release in releases:
        release_cards.append(
            '<li><a href="{url}">ECZOS {version} ({architecture})</a> '
            '— {published} — <a href="{url}.sha256">SHA-256</a></li>'.format(
                url=html.escape(release["url"].removeprefix("https://repo.easycomp.cloud/eczos/"), quote=True),
                version=html.escape(release["version"]),
                architecture=html.escape(release.get("architecture", "amd64")),
                published=html.escape(release["published"])))
    return """<!doctype html>
<html lang="nl">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ECZOS software repository</title>
  <style>
    :root {{ color-scheme: light dark; font-family: system-ui, sans-serif; }}
    body {{ max-width: 1100px; margin: 0 auto; padding: 32px 20px 64px; line-height: 1.5; }}
    h1 {{ margin-bottom: .25rem; }} h2 {{ margin-top: 2.25rem; }}
    .intro {{ color: #667085; }} code {{ background: rgba(127,127,127,.14); padding: .15rem .35rem; border-radius: 4px; }}
    table {{ width: 100%; border-collapse: collapse; }}
    th, td {{ text-align: left; vertical-align: top; padding: .65rem; border-bottom: 1px solid rgba(127,127,127,.3); }}
    th {{ white-space: nowrap; }} a {{ color: #16765b; }}
  </style>
</head>
<body>
  <h1>ECZOS software repository</h1>
  <p class="intro">Ondertekende software-updates en installatiekopieën voor EasyComp Zeeland Operating System.</p>
  <h2>ECZOS-installatiekopieën</h2>
  <ul>{release_cards}</ul>
  <h2>Stabiele softwarepakketten</h2>
  <table>
    <thead><tr><th>Pakket</th><th>Versie</th><th>Architectuur</th><th>Beschrijving</th></tr></thead>
    <tbody>{rows}</tbody>
  </table>
  <h2>Repository gebruiken</h2>
  <p>ECZOS-systemen ontvangen deze repository en de ondertekeningssleutel via het pakket <code>eczos-release</code>. Handmatige installatie is voor normale ECZOS-gebruikers niet nodig.</p>
</body>
</html>
""".format(release_cards="\n".join(release_cards) or "<li>Nog geen installatiekopieën gepubliceerd.</li>",
           rows="\n".join(rows) or '<tr><td colspan="4">Nog geen stabiele pakketten gepubliceerd.</td></tr>')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("repository", type=Path)
    parser.add_argument("release_directory", type=Path)
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--published", default=str(date.today()))
    args = parser.parse_args()

    packages_file = args.repository / "dists/trixie/main/binary-amd64/Packages.gz"
    if not packages_file.is_file():
        raise SystemExit(f"Stable package index is missing: {packages_file}")
    with gzip.open(packages_file, "rt", encoding="utf-8") as stream:
        packages = [item for item in deb822_paragraphs(stream.read())
                    if item.get("Package", "").startswith("eczos-")]

    image_name = f"ECZOS-{args.version}-amd64.iso"
    image = args.release_directory / "images" / image_name
    checksum_file = image.with_suffix(image.suffix + ".sha256")
    if not image.is_file() or not checksum_file.is_file():
        raise SystemExit(f"Release image or checksum is missing: {image}")
    expected = checksum_file.read_text(encoding="utf-8").split()[0].lower()
    actual = sha256(image)
    if expected != actual:
        raise SystemExit("Release image checksum mismatch")

    public_image = args.repository / "images" / image_name
    stage_image(image, public_image)
    atomic_text(public_image.with_suffix(public_image.suffix + ".sha256"), f"{actual}  {image_name}\n")
    releases = [{
        "version": args.version,
        "channel": "stable",
        "published": args.published,
        "architecture": "amd64",
        "size": image.stat().st_size,
        "url": f"https://repo.easycomp.cloud/eczos/images/{image_name}",
        "sha256": actual,
    }]
    atomic_text(args.repository / "releases.json",
                json.dumps({"schema": 1, "releases": releases}, ensure_ascii=False, indent=2) + "\n")
    atomic_text(args.repository / "index.html", render_index(packages, releases))
    print(f"Generated repository page with {len(packages)} packages and {len(releases)} release image.")


if __name__ == "__main__":
    main()
