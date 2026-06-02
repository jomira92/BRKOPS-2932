# BRKOPS-2932

NSO lab repository for BRKOPS-2932 demos.

This repo includes:
- `nso-observe-6.7/` project skeleton and automation
- service packages: `loopback-demo` and `ntp-min-service`
- customer prompt catalog: `NSO_MCP_CUSTOMER_PROMPTS.md`

This repo does not upload large/private artifacts by design:
- `nso-observe-6.7/images/` contents are ignored
- `nso-observe-6.7/neds/` contents are ignored
- only selected packages are tracked in `nso-observe-6.7/packages/`

## Project Goals

1. Build a reproducible NSO lab using Docker Compose.
2. Bring up netsim devices for realistic service testing.
3. Validate `loopback-demo` and `ntp-min-service` flows.
4. Enable customer troubleshooting workflows with NSO MCP prompts.

## What You Need Before Starting

1. Docker Desktop (or Docker Engine + Compose v2).
2. Cisco NSO image tarballs matching `NSO_VERSION` in `.env`:
	- `cisco-nso-build:<version>`
	- `cisco-nso-prod:<version>`
3. NED `.signed.bin` files for the device types you want in netsim.
4. A macOS/Linux shell with `make`.

## One-Time Setup

1. Open project:

```bash
cd nso-observe-6.7
```

2. Create environment file:

```bash
cp .env.example .env
```

3. Add NSO image tarballs to `images/` (or load images manually with `docker load`).

4. Add NED files to `neds/`.

5. Optional: adjust ports and credentials in `.env`.

## Step-by-Step Runbook (Goal Oriented)

### Step 1: Build the Lab Artifacts

Goal: verify NSO base images are available and compile packages.

```bash
make build
```

Success criteria:
- build completes without missing-image errors
- packages compile in the build container

### Step 2: Start Full Topology

Goal: bring up NSO + netsim + observability stack.

```bash
make up-all
```

Success criteria:
- containers are running
- NSO service is healthy

### Step 3: Access NSO and Validate Devices

Goal: confirm NSO login and managed device inventory.

```bash
make cli
```

In NSO CLI:

```text
show devices list
devices check-sync
```

Expected demo device naming pattern:
- `ios-0..3`
- `iosxr-0..3`

### Step 4: Test Services

Goal: validate tracked service packages function correctly.

Examples:
- create/update a `loopback-demo` instance
- create/update an `ntp-min-service` instance

Then validate sync status again:

```text
devices check-sync
```

### Step 5: Use NSO MCP Prompts

Goal: run customer-focused troubleshooting workflows.

Use prompts from:
- `NSO_MCP_CUSTOMER_PROMPTS.md`

These prompts are scoped to tool operations such as:
- `check-sync`, `compare-config`, `sync-from`, `sync-to`, `connect`, `ping`

## Daily Operations

From `nso-observe-6.7/`:

```bash
make logs      # follow container logs
make down      # stop containers, keep volumes
make clean     # full reset (removes volumes)
```

## Common Issues and Fixes

### Missing NSO images during build

Symptom: `make build` fails saying required images are missing.

Fix:
- place `.tar.gz` NSO image bundles into `images/`, or
- run `docker load -i <tarball>` for both build and prod images.

### No devices appear in NSO

Symptom: `show devices list` is empty.

Fix:
- confirm NED files are present in `neds/`
- rerun:

```bash
make clean
make build
make up-all
```

### Service commit blocked by drift

Symptom: commit/sync errors on device operations.

Fix in NSO CLI:

```text
devices check-sync
devices device <name> compare-config
devices device <name> sync-from
```

## Repository Layout

- `nso-observe-6.7/`: runnable NSO project
- `NSO_MCP_CUSTOMER_PROMPTS.md`: customer-ready MCP prompt examples

## Quick Start (Copy/Paste)

```bash
cd nso-observe-6.7
cp .env.example .env
# add NSO image tarballs to images/
# add NED .signed.bin files to neds/
make build
make up-all
make cli
```
