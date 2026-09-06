# 0008 — FreeOffice is selected but not yet redistributed

## Decision

SoftMaker FreeOffice 2024 is the intended familiar office suite for ECZOS
Desktop. LibreOffice is removed from the product profile. ECZOS will not embed,
mirror or preinstall FreeOffice in a redistributable ISO until EasyComp Zeeland
has written permission from SoftMaker covering OS-image redistribution and
automatic updates.

## Reason

SoftMaker documents free private and business use and publishes an official
Linux installer, but that is not by itself an explicit redistribution grant to
ECZOS. Executing a changing remote shell script during an image build would
also bypass the project's pinned-input and reproducibility requirements.

## Consequence

The desired office product and its blocked state are recorded in
`/usr/share/eczos/product/default-apps.json`. The image remains temporarily
without a bundled office suite. Once permission is received, ECZOS will package
or stage the vendor-approved artifact with a reviewed version, checksum,
license record, upgrade path and removal test.
