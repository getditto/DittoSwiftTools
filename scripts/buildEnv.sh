#!/usr/bin/env bash

# buildEnv.sh — Generate Env.swift from a .env file.
#
# Called by the "Generate Env.swift" Xcode build phase in DittoToolsApp:
#
#   "${SRCROOT}/../scripts/buildEnv.sh" "${SRCROOT}/../.env" "${SRCROOT}/${PROJECT}"
#
# Arguments:
#   $1 — Path to the .env file (e.g. DittoSwiftTools/.env)
#   $2 — Output directory for Env.swift (e.g. DittoToolsApp/DittoToolsApp/)
#
# If .env is absent but a .env.sample exists alongside it, the sample is used
# instead. That keeps Env.swift's struct shape stable so DittoService.swift
# compiles even on a fresh clone; the runtime validation in initializeDitto()
# surfaces any empty values with a clear error.

code=$(
    cat <<'EOS'

import Foundation

// This file is auto generated. Do not edit this, and edit .env instead.

struct Env {

EOS
)

if [ $# -ne 2 ]; then
    echo "error: buildEnv.sh requires 2 arguments." 1>&2
    echo "       Usage: buildEnv.sh /path/to/.env /output/directory" 1>&2
    exit 1
fi

input="$1"

# Fall back to .env.sample when .env is absent.
if [ ! -f "$input" ] && [ -f "$1.sample" ]; then
    input="$1.sample"
fi

if [ ! -f "$input" ]; then
    echo "error: No .env file found at '${1}'." 1>&2
    echo "       Copy .env.sample to .env and fill in your Ditto portal credentials:" 1>&2
    echo "         cp .env.sample .env" 1>&2
    echo "       See the README for details on obtaining credentials." 1>&2
    exit 1
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
    line="${line//[$'\r\n']/}"
    trimline="${line//[$'\t\r\n ']/}"
    if [ -n "$trimline" ] && [[ $trimline != \#* ]]; then
        KEY="${line%%=*}"
        VALUE="$(echo "${line#*=}" | sed 's/^[[:space:]]*//; s/^"//; s/"$//')"
        code=$(
            cat <<EOS
        $code
    static let $KEY = "$VALUE"
EOS
        )
    fi
done <"$input"

code=$(
    cat <<EOS
$code
}
EOS
)

echo "${code}" >"$2/Env.swift"

exit 0
