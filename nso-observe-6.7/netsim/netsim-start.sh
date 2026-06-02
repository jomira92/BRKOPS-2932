#!/bin/bash
set -euo pipefail

NETSIM_DIR="/netsim"
OUTPUT_DIR="/netsim-output"
READY_FILE="${OUTPUT_DIR}/.netsim-ready"
DEVICES_PER_NED="${NETSIM_DEVICES_PER_NED:-4}"
CONTAINER_HOSTNAME="${NETSIM_HOSTNAME:-netsim}"
PACKAGES_DIR="/nso/run/packages"

export PYTHONPATH="${PYTHONPATH:-/opt/ncs/current/src/ncs/pyapi}"

discover_ned_packages() {
    local found=0
    local pkg
    for pkg in "${PACKAGES_DIR}"/*/; do
        if [[ -d "${pkg}netsim" ]]; then
            echo "${pkg%/}"
            found=1
        fi
    done
    if [[ ${found} -eq 0 ]]; then
        echo "ERROR: No NED packages with netsim support found in ${PACKAGES_DIR}" >&2
        exit 1
    fi
}

extract_short_name() {
    local pkg_dir_name="$1"
    local name="${pkg_dir_name}"

    name="${name#cisco-}"

    name="${name%%-cli-*}"
    name="${name%%-netconf-*}"

    name="$(echo "${name}" | sed 's/-[0-9][0-9.]*$//')"

    if [[ -z "${name}" ]]; then
        name="${pkg_dir_name}"
    fi

    echo "${name}"
}

check_duplicate_prefixes() {
    local -a prefixes=("$@")
    local -A seen
    for p in "${prefixes[@]}"; do
        if [[ -n "${seen[${p}]+x}" ]]; then
            echo "ERROR: Duplicate netsim prefix '${p}' — two NEDs resolve to the same short name." >&2
            echo "       Check your NED packages in ${PACKAGES_DIR}" >&2
            exit 1
        fi
        seen["${p}"]=1
    done
}

netsim_network_exists() {
    ncs-netsim --dir "${NETSIM_DIR}" list >/dev/null 2>&1
}

# --- Main ---

mapfile -t ned_packages < <(discover_ned_packages)

mkdir -p "${OUTPUT_DIR}"
rm -f "${READY_FILE}"

if [[ ${#ned_packages[@]} -eq 0 ]]; then
    echo "ERROR: No NED packages with netsim support found in ${PACKAGES_DIR}" >&2
    exit 1
fi

echo "Discovered ${#ned_packages[@]} NED package(s):"
prefixes=()
for pkg in "${ned_packages[@]}"; do
    pkg_name="$(basename "${pkg}")"
    short_name="$(extract_short_name "${pkg_name}")"
    prefixes+=("${short_name}")
    echo "  - ${pkg_name}  →  prefix: ${short_name}-"
done

check_duplicate_prefixes "${prefixes[@]}"

if netsim_network_exists; then
    echo "Netsim network already exists in ${NETSIM_DIR}, skipping creation"
else
    first=true
    for i in "${!ned_packages[@]}"; do
        pkg="${ned_packages[${i}]}"
        prefix="${prefixes[${i}]}-"
        pkg_name="$(basename "${pkg}")"

        if ${first}; then
            echo "Creating ${DEVICES_PER_NED} netsim devices for '${pkg_name}' (prefix: ${prefix})..."
            ncs-netsim --dir "${NETSIM_DIR}" create-network "${pkg}" "${DEVICES_PER_NED}" "${prefix}"
            first=false
        else
            echo "Adding ${DEVICES_PER_NED} netsim devices for '${pkg_name}' (prefix: ${prefix})..."
            ncs-netsim --dir "${NETSIM_DIR}" add-to-network "${pkg}" "${DEVICES_PER_NED}" "${prefix}"
        fi
    done
fi

echo "Starting netsim devices..."
ncs-netsim --dir "${NETSIM_DIR}" start

echo "Generating device XML with hostname '${CONTAINER_HOSTNAME}'..."
ncs-netsim --dir "${NETSIM_DIR}" ncs-xml-init \
    | sed "s/127.0.0.1/${CONTAINER_HOSTNAME}/g" \
    > "${OUTPUT_DIR}/netsim-devices.xml"
echo "Device XML written to ${OUTPUT_DIR}/netsim-devices.xml"
touch "${READY_FILE}"
echo "Netsim readiness marker written to ${READY_FILE}"

echo "Netsim devices running — keeping container alive"
tail -f /dev/null
