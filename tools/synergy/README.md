# Synergy 1.10.1 voor Debian

Deze bundel installeert de bestaande Synergy 1.10.1 amd64-build op Debian 13.
De oude client vereist `libssl1.1`, daarom staat die compatibiliteitsbibliotheek
lokaal naast het installatieprogramma. Overige afhankelijkheden komen uit de
normale Debian-repositories.

Voer op de doelmachine als root uit:

```sh
bash install-synergy-debian.sh
```

De bundel is specifiek voor amd64. De Synergy-versie is bewust gelijk aan de
werkende installatie op de ECZOS-ontwikkelmachine; dit is geen nieuwe ECZOS-
runtime en wordt daarom niet in de ECZOS-ISO opgenomen.
