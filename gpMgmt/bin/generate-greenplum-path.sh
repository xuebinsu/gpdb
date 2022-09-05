#!/usr/bin/env bash

SET_PYTHONHOME="${1:-no}"
SET_PYTHONPATH="${2:-yes}"

cat <<"EOF"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ ! -L "${SCRIPT_DIR}" ]; then
    GPHOME=${SCRIPT_DIR}
else
    GPHOME=$(readlink "${SCRIPT_DIR}")
fi
EOF

if [ "${SET_PYTHONHOME}" = "yes" ]; then
	cat <<-"EOF"
	PYTHONHOME="${GPHOME}/ext/python"
	export PYTHONHOME

	PATH="${PYTHONHOME}/bin:${PATH}"
	LD_LIBRARY_PATH="${PYTHONHOME}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
	EOF
fi

if [ "${SET_PYTHONPATH}" = "yes" ]; then
	cat <<-"EOF"
	PYTHONPATH="${GPHOME}/lib/python"
	export PYTHONPATH
	EOF
fi

cat <<"EOF"
PATH="${GPHOME}/bin:${PATH}"
LD_LIBRARY_PATH="${GPHOME}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if [ -e "${GPHOME}/etc/openssl.cnf" ]; then
	OPENSSL_CONF="${GPHOME}/etc/openssl.cnf"
fi

export GPHOME
export PATH
export LD_LIBRARY_PATH
export OPENSSL_CONF
EOF
