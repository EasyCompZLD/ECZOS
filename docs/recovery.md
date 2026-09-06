# Recovery principles

Every ECZOS component must define removal and recovery before it is activated.

## Package recovery

Static branding packages should require no maintainer scripts. Removing or
purging them removes only files owned by that package. Theme activation belongs
to a separate package so missing artwork cannot damage package management.

## Desktop recovery

Keep a standard Plasma session available throughout development. An SDDM theme
failure must be recoverable by selecting a known Debian theme from a text console
or rescue boot. User defaults are applied once and are not enforced every login.

## Boot recovery

Plymouth and GRUB changes are introduced only after desktop/login packages pass
their lifecycle tests. A text boot path and a known-good kernel entry must remain
available. Snapshot the VM before every boot-stack change.

## Data recovery

ECZ Windows application prefixes are not user-document backups. Prefix removal
must identify user-created data and request confirmation before deletion. Backup
and system rollback technology will be chosen in a separate architecture decision.
