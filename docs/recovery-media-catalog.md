# ECZOS recovery media catalog

The recovery media creator works with local `.iso` and `.img` files. Online
version selection becomes available after `CatalogURL` in
`/etc/eczos/recovery-media.conf` points to a public HTTPS JSON document.

The catalog format is:

```json
{
  "schema": 1,
  "releases": [
    {
      "version": "1.0.0",
      "channel": "stable",
      "published": "2026-09-08",
      "url": "https://downloads.example.invalid/ECZOS-1.0.0-amd64.iso",
      "sha256": "64 lowercase or uppercase hexadecimal characters"
    }
  ]
}
```

Entries are sorted by `published`, newest first. The app accepts only HTTPS URLs
and verifies every download against `sha256`. The catalog service and ISO hosting
must be deployed before online downloads can be enabled. Updating the root-owned
configuration file does not require rebuilding the package.
