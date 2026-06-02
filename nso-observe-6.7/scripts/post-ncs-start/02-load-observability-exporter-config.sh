#!/bin/bash
set -e

OBS_CONFIG_XML="${OBS_CONFIG_XML:-/observability-config/observability-exporter-config.xml}"

if [[ ! -f "${OBS_CONFIG_XML}" ]]; then
  echo "Observability exporter config not found at ${OBS_CONFIG_XML}; skipping load"
  exit 0
fi

echo "Loading observability exporter configuration from ${OBS_CONFIG_XML}..."
ncs_load -l -m "${OBS_CONFIG_XML}"
echo "Observability exporter configuration load complete"