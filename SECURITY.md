# Security policy

Do not commit credentials, private keys, enrollment tokens, passwords or
preconfigured unattended-access secrets.

Security-sensitive reports for ECZOS should be handled privately by EasyComp
Zeeland until a public reporting address and disclosure policy are established.

The historical `ECZHOATOOLLinux-x86_64.deb` contains embedded remote-access
configuration. Treat its credential as compromised, rotate it outside this
repository and do not ship that package in future images.
