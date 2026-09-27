#!/usr/bin/env bash
set -Eeuo pipefail

[[ $(id -u) -eq 0 ]] || { printf 'Run as root on the test host.\n' >&2; exit 2; }
dpkg-query -W -f='${Status}\n' eczos-platform-core | grep -Fx 'install ok installed'
test -x /usr/bin/eczos-capability
test -x /usr/bin/eczos-config-migrate
bash -n /usr/bin/eczos-capability /usr/bin/eczos-config-migrate
test -r /usr/share/eczos/platform/schema/capability-result-v1.json
jq -e '.properties.status.enum | index("ready")' \
    /usr/share/eczos/platform/schema/capability-result-v1.json >/dev/null
/usr/bin/eczos-capability platform-core migration ready framework-available \
    'Migration framework is available.' '{"idempotent":true}' | \
    jq -e '.schema == 1 and .status == "ready" and .details.idempotent' >/dev/null

migration_test=$(mktemp -d /tmp/eczos-platform-migration.XXXXXX)
trap 'rm -rf "$migration_test"' EXIT
install -d -m 0755 "$migration_test/migrations/test-component" "$migration_test/state"
cat >"$migration_test/migrations/test-component/0001-smoke-test" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
printf 'applied\n' >>"${ECZOS_MIGRATION_TEST_MARKER:?}"
SCRIPT
chmod 0755 "$migration_test/migrations/test-component/0001-smoke-test"
export ECZOS_MIGRATIONS_ROOT="$migration_test/migrations"
export ECZOS_MIGRATION_STATE_ROOT="$migration_test/state"
export ECZOS_MIGRATION_LOCK_FILE="$migration_test/migration.lock"
export ECZOS_MIGRATION_TEST_MARKER="$migration_test/marker"
/usr/bin/eczos-config-migrate run test-component
/usr/bin/eczos-config-migrate run test-component
test "$(wc -l <"$migration_test/marker")" -eq 1
/usr/bin/eczos-config-migrate check test-component >/dev/null
/usr/bin/eczos-config-migrate status test-component --json | jq -e \
    '.schemaVersion == 1 and .healthy == true and .pending == 0 and .applied == 1' >/dev/null
jq -e '.applied["0001-smoke-test"].sha256 | length == 64' \
    "$migration_test/state/test-component.json" >/dev/null
test "$(stat -c %a "$migration_test/state/test-component.json")" = 644
cp "$migration_test/migrations/test-component/0001-smoke-test" "$migration_test/original-migration"
printf '\n# changed after application\n' >>"$migration_test/migrations/test-component/0001-smoke-test"
if /usr/bin/eczos-config-migrate run test-component >/dev/null 2>&1; then
    printf 'Migration drift was not rejected.\n' >&2
    exit 1
fi
mv "$migration_test/original-migration" "$migration_test/migrations/test-component/0001-smoke-test"
cat >"$migration_test/migrations/test-component/0002-failing-migration" <<'SCRIPT'
#!/usr/bin/env bash
exit 42
SCRIPT
chmod 0755 "$migration_test/migrations/test-component/0002-failing-migration"
if /usr/bin/eczos-config-migrate run test-component >/dev/null 2>&1; then
    printf 'Failing migration was accepted.\n' >&2
    exit 1
fi
/usr/bin/eczos-config-migrate status test-component --json | jq -e \
    '.healthy == false and .failures[0].failure.migration == "0002-failing-migration" and .failures[0].failure.exitCode == 42' >/dev/null
printf 'eczos-platform-core installed-package smoke test passed\n'
