# NSO-MCP Customer Prompt Examples

These are practical prompts customers can paste into an NSO-MCP enabled assistant.
All prompts below are compatible with this toolset only:

- nso-devices_device_sync_from
- nso-devices_device_sync_to
- nso-devices_device_check_sync
- nso-devices_device_compare_config
- nso-devices_device_connect
- nso-devices_device_disconnect
- nso-devices_device_ping
- nso-nso_read_schema
- nso-nso_read_config
- nso-nso_read_operational
- nso-echo

## 1. Quick Health Check
Prompt:

```text
Check these devices and give me a health summary:
- ios-0, ios-1, ios-2, ios-3
- iosxr-0, iosxr-1, iosxr-2, iosxr-3
- reachability
- sync status
- device connection status
Show only devices that need attention first.
```

Expected value:
- Fast triage view for NOC teams.
- Prioritizes problem devices immediately.

## 2. Out-of-Sync Troubleshooting
Prompt:

```text
For these devices only: ios-0, ios-1, ios-2, ios-3, iosxr-0, iosxr-1, iosxr-2, iosxr-3,
find all out-of-sync devices. For each one show compare-config differences and
recommend whether I should run sync-from or sync-to.
```

Expected value:
- Identifies drift and gives actionable next step.
- Reduces operator guesswork.

## 3. Single Device Deep Dive
Prompt:

```text
Investigate iosxr-0:
1) check-sync
2) compare-config
3) connectivity test
4) summarize root cause and exact remediation commands.
If iosxr-0 depends on peer devices, check iosxr-1 and ios-0 as adjacent context.
```

Expected value:
- One-click troubleshooting workflow for a specific device.

## 4. Pre-Change Risk Check
Prompt:

```text
Before I run sync-to for iosxr-1, run a pre-change assessment using these devices:
- iosxr-1 (target), iosxr-0 and ios-1 (peer checks)
- ping and connect status
- current check-sync result
- compare-config diff summary
Return a go/no-go decision for sync-to on iosxr-1.
```

Expected value:
- Prevents failed changes.
- Creates operational guardrails.

## 5. Slow Commit Analysis
Prompt:

```text
For devices ios-0, ios-1, ios-2, ios-3, iosxr-0, iosxr-1, iosxr-2, iosxr-3,
read operational data related to device operations and identify any currently slow or failing
device interactions. For each finding, name the exact device and likely cause.
```

Expected value:
- Uses available operational-state data to flag active device issues.
- Useful for day-2 troubleshooting with read-only access.

## 6. Commit Queue Backlog
Prompt:

```text
Using operational data, show any active device synchronization issues for:
ios-0, ios-1, ios-2, ios-3, iosxr-0, iosxr-1, iosxr-2, iosxr-3.
For each affected device, include:
- ping/connect result
- check-sync state
- whether sync-from or sync-to is the safer next action.
```

Expected value:
- Produces a clear, action-oriented recovery list per device.

## 7. Service Failure Root Cause
Prompt:

```text
My change failed on these devices: iosxr-0, iosxr-1, ios-0.
Using only device and NSO read tools:
- run ping/connect/check-sync/compare-config on each device
- summarize likely failure root cause per device
- provide exact remediation sequence (sync-from or sync-to, then validation).
```

Expected value:
- Gives practical root-cause guidance without external logging tools.
- Produces retry steps from available NSO operations.

## 8. Security and Access Validation
Prompt:

```text
Validate whether user oper can execute sync-from.
Test against these devices: ios-0 and iosxr-0.
If blocked, read config under AAA/NACM and show which rule likely denies it,
then suggest the minimal safe permission change.
```

Expected value:
- Speeds up RBAC/NACM troubleshooting.
- Supports least-privilege operations.

## 9. Maintenance Window Assistant
Prompt:

```text
I have a 30-minute maintenance window.
Create an execution checklist for service updates on ios-0, ios-1, iosxr-0, and iosxr-1:
- pre-checks
- change steps
- validation checks
- rollback plan if sync issues appear (using sync-from/sync-to decision points).
```

Expected value:
- Standardized runbook generation.
- Safer execution under time pressure.

## 10. Executive Summary Prompt
Prompt:

```text
Generate an executive summary for today's NSO operations:
- include this device scope explicitly: ios-0, ios-1, ios-2, ios-3, iosxr-0, iosxr-1, iosxr-2, iosxr-3
- current reachability status
- current sync status
- device drift incidents from compare-config
- recommended actions and pending risks.
```

Expected value:
- Business-facing summary from current NSO device state.

## Tips for Better Results
- Include time ranges, for example: last 15m, last 24h.
- Use this default inventory in prompts: ios-0, ios-1, ios-2, ios-3, iosxr-0, iosxr-1, iosxr-2, iosxr-3.
- Ask for both diagnosis and concrete remediation steps.
- Request output in table format when sharing in incident channels.

## Note on Scope
- Prompts intentionally avoid non-listed capabilities (for example trace analytics, queue internals, or external observability backends).
- If you later add tools for logs/metrics/traces, these prompts can be extended.
