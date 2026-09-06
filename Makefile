.PHONY: test package

test:
	./scripts/verify-source.sh

package:
	cd packages/eczos-branding && dpkg-buildpackage -us -uc -b
