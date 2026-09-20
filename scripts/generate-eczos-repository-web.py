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


PACKAGE_DESCRIPTIONS = {
    "eczos-archive-keyring": {
        "nl": "Ondertekeningssleutel voor de ECZOS-softwarerepository",
        "en": "Signing key for the ECZOS software repository",
        "de": "Signaturschlüssel für das ECZOS-Software-Repository",
        "fr": "Clé de signature du dépôt de logiciels ECZOS",
    },
    "eczos-branding": {
        "nl": "Visuele identiteit van ECZOS",
        "en": "ECZOS visual identity assets",
        "de": "Visuelles Erscheinungsbild von ECZOS",
        "fr": "Éléments d’identité visuelle ECZOS",
    },
    "eczos-desktop": {
        "nl": "Complete ECZOS-desktopomgeving",
        "en": "Complete ECZOS desktop environment",
        "de": "Vollständige ECZOS-Desktop-Umgebung",
        "fr": "Environnement de bureau ECZOS complet",
    },
    "eczos-desktop-apps": {
        "nl": "Complete set ingebouwde ECZOS-apps",
        "en": "Complete set of native ECZOS applications",
        "de": "Vollständiger Satz nativer ECZOS-Anwendungen",
        "fr": "Ensemble complet d’applications ECZOS natives",
    },
    "eczos-desktop-defaults": {
        "nl": "Standaardinstellingen voor de ECZOS-desktop",
        "en": "Default settings for the ECZOS desktop",
        "de": "Standardeinstellungen für den ECZOS-Desktop",
        "fr": "Paramètres par défaut du bureau ECZOS",
    },
    "eczos-gaming-core": {
        "nl": "Hardware- en Proton-basis voor ECZ Gaming",
        "en": "Hardware and Proton foundation for ECZ Gaming",
        "de": "Hardware- und Proton-Basis für ECZ Gaming",
        "fr": "Base matérielle et Proton pour ECZ Gaming",
    },
    "eczos-installer": {
        "nl": "Presentatie en instellingen van het ECZOS-installatieprogramma",
        "en": "ECZOS installer presentation and settings",
        "de": "Darstellung und Einstellungen des ECZOS-Installationsprogramms",
        "fr": "Présentation et paramètres du programme d’installation ECZOS",
    },
    "eczos-network-optical": {
        "nl": "Deel fysieke cd- en dvd-stations tussen ECZOS-computers",
        "en": "Share physical CD and DVD drives between ECZOS computers",
        "de": "Physische CD- und DVD-Laufwerke zwischen ECZOS-Computern teilen",
        "fr": "Partager des lecteurs CD et DVD physiques entre ordinateurs ECZOS",
    },
    "eczos-oobe": {
        "nl": "Welkomst- en installatiehulp voor de eerste start van ECZOS",
        "en": "ECZOS first-start welcome and setup experience",
        "de": "Begrüßung und Einrichtung beim ersten Start von ECZOS",
        "fr": "Accueil et configuration au premier démarrage d’ECZOS",
    },
    "eczos-platform-tools": {
        "nl": "Gebruiksvriendelijke beheer- en herstelhulpmiddelen voor ECZOS",
        "en": "User-friendly management and recovery tools for ECZOS",
        "de": "Benutzerfreundliche Verwaltungs- und Wiederherstellungswerkzeuge für ECZOS",
        "fr": "Outils conviviaux de gestion et de récupération pour ECZOS",
    },
    "eczos-plymouth-theme": {
        "nl": "ECZOS-opstartanimatie voor Plymouth",
        "en": "ECZOS startup animation for Plymouth",
        "de": "ECZOS-Startanimation für Plymouth",
        "fr": "Animation de démarrage ECZOS pour Plymouth",
    },
    "eczos-recovery-media": {
        "nl": "Maak op een veilige manier ECZOS-herstelmedia",
        "en": "Create ECZOS recovery media safely",
        "de": "ECZOS-Wiederherstellungsmedien sicher erstellen",
        "fr": "Créer un support de récupération ECZOS en toute sécurité",
    },
    "eczos-release": {
        "nl": "Release-identiteit en repositoryconfiguratie voor ECZOS",
        "en": "ECZOS release identity and repository configuration",
        "de": "ECZOS-Versionsidentität und Repository-Konfiguration",
        "fr": "Identité de version et configuration du dépôt ECZOS",
    },
    "eczos-sddm-theme": {
        "nl": "ECZOS-aanmeldscherm voor SDDM",
        "en": "ECZOS login theme for SDDM",
        "de": "ECZOS-Anmeldedesign für SDDM",
        "fr": "Thème de connexion ECZOS pour SDDM",
    },
    "eczos-windows-core": {
        "nl": "Beheerde compatibiliteitslaag voor Windows-apps in ECZOS",
        "en": "Managed compatibility layer for Windows applications in ECZOS",
        "de": "Verwaltete Kompatibilitätsschicht für Windows-Anwendungen in ECZOS",
        "fr": "Couche de compatibilité gérée pour les applications Windows dans ECZOS",
    },
}


def render_index(packages, releases):
    rows = []
    for package in sorted(packages, key=lambda item: item.get("Package", "")):
        filename = html.escape(package.get("Filename", ""), quote=True)
        name = html.escape(package.get("Package", ""))
        version = html.escape(package.get("Version", ""))
        architecture = html.escape(package.get("Architecture", ""))
        description = html.escape(package.get("Description", "").split("\n", 1)[0])
        translated_descriptions = PACKAGE_DESCRIPTIONS.get(package.get("Package", ""), {})
        description_attributes = " ".join(
            f'data-description-{language}="{html.escape(value, quote=True)}"'
            for language, value in translated_descriptions.items())
        rows.append(
            f'<tr class="package-row" data-search="{name.lower()} {description.lower()}">'
            f'<td><a href="{filename}">{name}</a></td><td>{version}</td>'
            f'<td>{architecture}</td><td class="package-description" {description_attributes}>'
            f'{description}</td></tr>')
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
    * {{ box-sizing: border-box; }}
    body {{ font-family: Arial, sans-serif; background: #f7f7f7; color: #202124; margin: 0; padding: 20px; line-height: 1.5; }}
    .container {{ max-width: 1000px; margin: auto; background: #fff; padding: 30px; box-shadow: 0 0 10px rgba(0,0,0,.1); }}
    header {{ position: relative; text-align: center; margin-bottom: 30px; }}
    header img {{ display: block; width: auto; max-width: 150px; height: auto; max-height: 120px; object-fit: contain; margin: 0 auto 10px; }}
    h1 {{ color: #003366; margin: 0 0 5px; }}
    h2 {{ color: #003366; margin: 32px 0 12px; }}
    p {{ color: #555; }}
    a {{ color: #00509e; }}
    .language {{ position: absolute; top: 0; right: 0; }}
    .language label {{ position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); }}
    select, .search input {{ border: 1px solid #ccc; border-radius: 4px; padding: 9px 11px; background: #fff; color: #202124; }}
    .release-list {{ padding-left: 22px; }}
    .search {{ margin: 20px 0; text-align: center; }}
    .search input {{ width: min(100%, 560px); }}
    .table-wrap {{ overflow-x: auto; }}
    table {{ width: 100%; border-collapse: collapse; }}
    thead {{ background: #003366; color: #fff; }}
    th, td {{ padding: 12px; border: 1px solid #ddd; text-align: left; vertical-align: top; }}
    th {{ white-space: nowrap; cursor: pointer; }}
    tbody tr:nth-child(even) {{ background: #f2f2f2; }}
    code {{ background: #eef1f4; color: #202124; padding: 2px 5px; border-radius: 4px; }}
    .empty {{ display: none; text-align: center; color: #666; padding: 18px; }}
    footer {{ text-align: center; margin-top: 40px; font-size: .9em; color: #777; }}
    @media (max-width: 680px) {{
      body {{ padding: 0; }} .container {{ padding: 22px 14px; min-height: 100vh; }}
      .language {{ position: static; margin-bottom: 16px; }} header img {{ max-width: 135px; max-height: 96px; }}
      h1 {{ font-size: 1.65rem; }} th, td {{ padding: 9px; }}
    }}
  </style>
</head>
<body>
<div class="container">
  <header>
    <div class="language">
      <label for="language" data-i18n="language">Taal</label>
      <select id="language" aria-label="Taal">
        <option value="nl">Nederlands</option><option value="en">English</option>
        <option value="de">Deutsch</option><option value="fr">Français</option>
      </select>
    </div>
    <img src="https://easycompzeeland.nl/wp-content/uploads/2021/05/EasyComp-Zeeland-ECZ-logo-2020-Vectorv2_0000s_0010s_0000s_0000__Groep_@01x.png"
         onerror="this.onerror=null;this.src='assets/eczos-logo-dark.png'"
         alt="EasyComp Zeeland Logo">
    <h1 data-i18n="title">ECZOS-softwarerepository</h1>
    <p data-i18n="intro">Ondertekende software-updates en installatiekopieën voor EasyComp Zeeland Operating System.</p>
  </header>
  <main>
    <h2 data-i18n="images">ECZOS-installatiekopieën</h2>
    <ul class="release-list">{release_cards}</ul>
    <h2 data-i18n="packages">Stabiele softwarepakketten</h2>
    <div class="search"><input id="package-search" type="search" data-i18n-placeholder="search" placeholder="Zoek pakketten…" autocomplete="off"></div>
    <div class="table-wrap"><table id="packages-table">
      <thead><tr><th data-i18n="package">Pakket</th><th data-i18n="version">Versie</th><th data-i18n="architecture">Architectuur</th><th data-i18n="description">Beschrijving</th></tr></thead>
      <tbody>{rows}</tbody>
    </table></div>
    <p id="empty" class="empty" data-i18n="empty">Geen pakketten gevonden.</p>
    <h2 data-i18n="using">Repository gebruiken</h2>
    <p data-i18n-html="usage">ECZOS-systemen ontvangen deze repository en de ondertekeningssleutel via het pakket <code>eczos-release</code>. Handmatige installatie is voor normale ECZOS-gebruikers niet nodig.</p>
  </main>
  <footer data-i18n="footer">© {year} EasyComp Zeeland. Alle rechten voorbehouden.</footer>
</div>
<script>
const translations = {translations};
const supported = ['nl', 'en', 'de', 'fr'];
const languageSelect = document.getElementById('language');
const search = document.getElementById('package-search');
const rows = [...document.querySelectorAll('.package-row')];
function setLanguage(language) {{
  if (!supported.includes(language)) language = 'en';
  document.documentElement.lang = language;
  languageSelect.value = language;
  localStorage.setItem('eczos-repository-language', language);
  const dictionary = translations[language];
  document.querySelectorAll('[data-i18n]').forEach(node => node.textContent = dictionary[node.dataset.i18n]);
  document.querySelectorAll('[data-i18n-placeholder]').forEach(node => node.placeholder = dictionary[node.dataset.i18nPlaceholder]);
  document.querySelectorAll('[data-i18n-html]').forEach(node => node.innerHTML = dictionary[node.dataset.i18nHtml]);
  document.querySelectorAll('.package-description').forEach(node => {{
    node.textContent = node.dataset['description' + language.charAt(0).toUpperCase() + language.slice(1)] || node.textContent;
  }});
  filterPackages();
}}
function filterPackages() {{
  const query = search.value.trim().toLocaleLowerCase(document.documentElement.lang);
  let shown = 0;
  rows.forEach(row => {{
    const visible = !query || row.textContent.toLocaleLowerCase(document.documentElement.lang).includes(query);
    row.hidden = !visible; if (visible) shown++;
  }});
  document.getElementById('empty').style.display = shown ? 'none' : 'block';
}}
languageSelect.addEventListener('change', event => setLanguage(event.target.value));
search.addEventListener('input', filterPackages);
const preferred = localStorage.getItem('eczos-repository-language') || navigator.language.slice(0, 2);
setLanguage(supported.includes(preferred) ? preferred : 'en');
</script>
</body>
</html>
""".format(
        release_cards="\n".join(release_cards) or '<li data-i18n="noImages">Nog geen installatiekopieën gepubliceerd.</li>',
        rows="\n".join(rows) or '<tr><td colspan="4" data-i18n="noPackages">Nog geen stabiele pakketten gepubliceerd.</td></tr>',
        year=date.today().year,
        translations=json.dumps({
            "nl": {"language": "Taal", "title": "ECZOS-softwarerepository", "intro": "Ondertekende software-updates en installatiekopieën voor EasyComp Zeeland Operating System.", "images": "ECZOS-installatiekopieën", "packages": "Stabiele softwarepakketten", "search": "Zoek pakketten…", "package": "Pakket", "version": "Versie", "architecture": "Architectuur", "description": "Beschrijving", "empty": "Geen pakketten gevonden.", "using": "Repository gebruiken", "usage": "ECZOS-systemen ontvangen deze repository en de ondertekeningssleutel via het pakket <code>eczos-release</code>. Handmatige installatie is voor normale ECZOS-gebruikers niet nodig.", "footer": f"© {date.today().year} EasyComp Zeeland. Alle rechten voorbehouden.", "noImages": "Nog geen installatiekopieën gepubliceerd.", "noPackages": "Nog geen stabiele pakketten gepubliceerd."},
            "en": {"language": "Language", "title": "ECZOS software repository", "intro": "Signed software updates and installation images for EasyComp Zeeland Operating System.", "images": "ECZOS installation images", "packages": "Stable software packages", "search": "Search packages…", "package": "Package", "version": "Version", "architecture": "Architecture", "description": "Description", "empty": "No packages found.", "using": "Using the repository", "usage": "ECZOS systems receive this repository and its signing key through the <code>eczos-release</code> package. Manual installation is not needed on normal ECZOS systems.", "footer": f"© {date.today().year} EasyComp Zeeland. All rights reserved.", "noImages": "No installation images have been published yet.", "noPackages": "No stable packages have been published yet."},
            "de": {"language": "Sprache", "title": "ECZOS-Software-Repository", "intro": "Signierte Softwareaktualisierungen und Installationsabbilder für EasyComp Zeeland Operating System.", "images": "ECZOS-Installationsabbilder", "packages": "Stabile Softwarepakete", "search": "Pakete suchen…", "package": "Paket", "version": "Version", "architecture": "Architektur", "description": "Beschreibung", "empty": "Keine Pakete gefunden.", "using": "Repository verwenden", "usage": "ECZOS-Systeme erhalten dieses Repository und den Signaturschlüssel über das Paket <code>eczos-release</code>. Auf normalen ECZOS-Systemen ist keine manuelle Installation erforderlich.", "footer": f"© {date.today().year} EasyComp Zeeland. Alle Rechte vorbehalten.", "noImages": "Noch keine Installationsabbilder veröffentlicht.", "noPackages": "Noch keine stabilen Pakete veröffentlicht."},
            "fr": {"language": "Langue", "title": "Dépôt de logiciels ECZOS", "intro": "Mises à jour logicielles signées et images d’installation pour EasyComp Zeeland Operating System.", "images": "Images d’installation ECZOS", "packages": "Paquets logiciels stables", "search": "Rechercher des paquets…", "package": "Paquet", "version": "Version", "architecture": "Architecture", "description": "Description", "empty": "Aucun paquet trouvé.", "using": "Utiliser le dépôt", "usage": "Les systèmes ECZOS reçoivent ce dépôt et sa clé de signature via le paquet <code>eczos-release</code>. Aucune installation manuelle n’est nécessaire sur un système ECZOS normal.", "footer": f"© {date.today().year} EasyComp Zeeland. Tous droits réservés.", "noImages": "Aucune image d’installation n’a encore été publiée.", "noPackages": "Aucun paquet stable n’a encore été publié."},
        }, ensure_ascii=False).replace("</", "<\\/"))


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
    source_root = Path(__file__).resolve().parent.parent
    logo_candidates = (
        source_root / "packages/eczos-branding/assets/logo/logo-dark.png",
        source_root / "assets/usr/share/ecz/branding/logo/logo.png",
        source_root / "packages/eczos-branding/assets/logo/logo.png",
    )
    logo_source = next((candidate for candidate in logo_candidates if candidate.is_file()), None)
    if logo_source is None:
        raise SystemExit("ECZOS logo is missing from the source tree")
    stage_image(logo_source, args.repository / "assets/eczos-logo-dark.png")
    atomic_text(args.repository / "index.html", render_index(packages, releases))
    print(f"Generated repository page with {len(packages)} packages and {len(releases)} release image.")


if __name__ == "__main__":
    main()
