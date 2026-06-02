# NSO NACM Rules — Step-by-Step Guide (XPath Focus)

NACM (NETCONF Access Control Model, RFC 8341) is the built-in authorization framework in NSO.
It controls **who** can read, write, or execute **what** paths in the NSO data model.
Rules use **XPath 1.0** expressions to identify the nodes they protect.

---

## Concepts Overview

| Term | Description |
|---|---|
| **Group** | A named set of users |
| **Rule list** | An ordered collection of rules tied to a group |
| **Rule** | A single allow/deny entry for a path, RPC, or module |
| **`path`** | XPath expression identifying the target data node(s) |
| **`when`** | Optional XPath condition — rule only fires when this evaluates to true |
| **Exec default** | What happens when no rule matches an RPC |
| **Write default** | What happens when no rule matches a write operation |
| **Read default** | What happens when no rule matches a read operation |

---

## XPath Path Basics in NACM

NACM `path` values are **schema node identifiers** — a restricted subset of XPath.
Key rules:

- Paths are **absolute** — always start with `/`.
- Every node name **must** be namespace-prefixed when used in XML (CLI is more relaxed).
- Key predicates (`[key='value']`) narrow the rule to a specific list instance.
- Wildcards select all instances of a list.
- The `when` field is a **full XPath 1.0 boolean expression** evaluated against the access request context.

### Namespace prefixes used in NSO NACM paths

| Prefix | Namespace | Used for |
|---|---|---|
| `ncs` | `http://tail-f.com/ns/ncs` | Core NSO objects (`/ncs:devices`, `/ncs:services`, etc.) |
| `nacm` | `urn:ietf:params:xml:ns:yang:ietf-netconf-acm` | NACM config itself |
| `acm` | `http://tail-f.com/ns/acm` | Tail-f ACM extensions |
| `ios` | (NED-specific) | IOS device config nodes |

> In the **NSO CLI** you can omit namespace prefixes in `path`. In **XML init files** you must declare and use them.

---

## Step 1 — Enable NACM

```bash
ncs_cli -u admin -C
```

```
show nacm
```

Expected output includes `enable true`. If not:

```
config
 nacm enable
commit
```

---

## Step 2 — Create a NACM Group

```
config
 nacm groups group NOC-OPERATORS
  user-name [ alice bob charlie ]
 !
commit
```

> Use `user-name [ * ]` to match all authenticated users.

---

## Step 3 — Create a Rule List

```
config
 nacm rule-list NOC-READ-ONLY
  group [ NOC-OPERATORS ]
  rule ALLOW-READ-DEVICES
   path        /devices
   access-operations read
   action      permit
  !
  rule DENY-WRITE-DEVICES
   path        /devices
   access-operations create update delete
   action      deny
  !
 !
commit
```

---

## Step 4 — XPath Path Examples

This is the core of NACM. The `path` field accepts XPath expressions that select one or more schema nodes.

### 4.1 Root and subtree paths

| Path | What it covers |
|---|---|
| `/` | The entire data tree |
| `/devices` | All device management (device list, authgroups, global settings) |
| `/devices/device` | All device list entries |
| `/devices/device/config` | Configuration subtree of every device |
| `/services` | All service instances |
| `/ncs:devices` | Same as above, explicit namespace (required in XML) |

```
rule ALLOW-ALL-DEVICES-READ
 path              /devices
 access-operations read
 action            permit
!
```

---

### 4.2 Key predicates — target a specific list instance

Use `[key='value']` to scope a rule to a single named entry.

```
rule OPS-ONLY-IOS0
 path              /devices/device[name='ios-0']
 access-operations read
 action            permit
!
```

```
rule ALLOW-NTP-SERVICE-INSTANCE
 path              /services/ntp-min-service[name='CORE-NTP']
 access-operations *
 action            permit
!
```

```
rule ALLOW-SPECIFIC-AUTHGROUP
 path              /devices/authgroups/group[name='default']
 access-operations read
 action            permit
!
```

> Key predicates work with **any list key**, not just `name`. Match on any leaf that is declared as `key` in the YANG model.

---

### 4.3 Deep paths — lock down a single leaf or container

Pinpoint a specific node deep inside the model to give fine-grained control.

```
rule READ-DEVICE-PLATFORM-ONLY
 path              /devices/device/platform
 access-operations read
 action            permit
!
```

```
rule DENY-AUTHGROUP-PASSWORD
 path              /devices/authgroups/group/umap/remote-password
 access-operations read
 action            deny
!
```

```
rule DENY-DEVICE-SSH-KEYS
 path              /devices/device/ssh/host-key
 access-operations read
 action            deny
!
```

```
rule ALLOW-DEVICE-STATE-ONLY
 path              /devices/device/state
 access-operations read
 action            permit
!
```

---

### 4.4 Wildcards — match multiple list instances

A path ending at a list node **without** a key predicate matches **all** instances.

```
rule ALL-DEVICE-CONFIG-READ
 path              /devices/device/config
 access-operations read
 action            permit
!
```

```
rule ALL-NTP-SERVICE-INSTANCES-READ
 path              /services/ntp-min-service
 access-operations read
 action            permit
!
```

---

### 4.5 Multiple sibling subtrees — one rule per path

NACM rules are 1:1 with paths. To allow two sibling subtrees, write two rules:

```
rule ALLOW-DEVICES-READ
 path              /devices
 access-operations read
 action            permit
!
rule ALLOW-SERVICES-READ
 path              /services
 access-operations read
 action            permit
!
rule DENY-EVERYTHING-ELSE
 path              /
 access-operations *
 action            deny
!
```

---

### 4.6 XPath namespace prefixes in XML init files

In XML you **must** declare every prefix used in the `path` value.

```xml
<!-- Simple subtree -->
<rule>
  <name>ALLOW-READ-DEVICES</name>
  <path xmlns:ncs="http://tail-f.com/ns/ncs">/ncs:devices</path>
  <access-operations>read</access-operations>
  <action>permit</action>
</rule>

<!-- Key predicate on a specific device -->
<rule>
  <name>ALLOW-SPECIFIC-DEVICE</name>
  <path xmlns:ncs="http://tail-f.com/ns/ncs">
    /ncs:devices/ncs:device[ncs:name='ios-0']
  </path>
  <access-operations>read</access-operations>
  <action>permit</action>
</rule>

<!-- Deep path to a single leaf -->
<rule>
  <name>DENY-AUTHGROUP-PASSWORDS</name>
  <path xmlns:ncs="http://tail-f.com/ns/ncs">
    /ncs:devices/ncs:authgroups/ncs:group/ncs:umap/ncs:remote-password
  </path>
  <access-operations>read</access-operations>
  <action>deny</action>
</rule>

<!-- Key predicate on a service instance -->
<rule>
  <name>ALLOW-PROD-NTP-ONLY</name>
  <path xmlns:ncs="http://tail-f.com/ns/ncs">
    /ncs:services/ncs:ntp-min-service[ncs:name='PROD-NTP']
  </path>
  <access-operations>*</access-operations>
  <action>permit</action>
</rule>
```

---

## Step 5 — The `when` Condition (XPath boolean filter)

`when` is an **optional** XPath 1.0 expression. The rule is only evaluated if `when` returns `true`.
It is evaluated against the **access request context node** — the data node being accessed.

> `when` is a Tail-f extension (`tailf-acm`). It is supported in NSO but is not part of base RFC 8341.

### 5.1 Match on a leaf value in the same list instance

Allow read of a device only if its NED type is IOS:

```
rule READ-IOS-DEVICES-ONLY
 path              /devices/device
 access-operations read
 action            permit
 when              "device-type/cli/ned-id = 'ios-id:cisco-ios'"
!
```

Deny exec actions on locked devices:

```
rule DENY-LOCKED-DEVICE-EXEC
 path              /devices/device
 access-operations exec
 action            deny
 when              "state/admin-state = 'locked'"
!
```

### 5.2 Match on a string prefix

Allow access only to devices whose name starts with `ios-`:

```
rule READ-IOS-PREFIX-DEVICES
 path              /devices/device
 access-operations read
 action            permit
 when              "starts-with(name, 'ios-')"
!
```

Allow access only to services whose instance name contains `PROD`:

```
rule PROD-SERVICES-ONLY
 path              /services/ntp-min-service
 access-operations *
 action            permit
 when              "contains(name, 'PROD')"
!
```

Block access to any device whose name starts with `lab-`:

```
rule DENY-LAB-DEVICES
 path              /devices/device
 access-operations *
 action            deny
 when              "starts-with(name, 'lab-')"
!
```

### 5.3 Match on a numeric value or comparison

Deny writes to any device that has active alarms:

```
rule DENY-ALARM-DEVICES-WRITE
 path              /devices/device
 access-operations create update delete
 action            deny
 when              "count(alarms/alarm) > 0"
!
```

Allow read only when a device has been synced (last-transaction-id is not empty):

```
rule READ-SYNCED-DEVICES-ONLY
 path              /devices/device
 access-operations read
 action            permit
 when              "string-length(state/last-transaction-id) > 0"
!
```

### 5.4 Combine conditions with `and` / `or`

Allow read only for IOS devices that are operationally enabled:

```
rule READ-SYNCED-IOS
 path              /devices/device
 access-operations read
 action            permit
 when              "starts-with(name, 'ios-') and state/oper-state = 'enabled'"
!
```

Allow access to either the staging or production NTP service instance:

```
rule NTP-STAGING-OR-PROD
 path              /services/ntp-min-service
 access-operations read
 action            permit
 when              "name = 'NTP-STAGING' or name = 'NTP-PROD'"
!
```

Deny write if the device is either locked or oper-state is disabled:

```
rule DENY-WRITE-UNAVAILABLE
 path              /devices/device
 access-operations create update delete
 action            deny
 when              "state/admin-state = 'locked' or state/oper-state = 'disabled'"
!
```

### 5.5 Negate with `not()`

Allow read everywhere **except** NACM config itself:

```
rule ALLOW-READ-EXCEPT-NACM
 path              /
 access-operations read
 action            permit
 when              "not(self::nacm)"
!
```

Allow access to all devices that are **not** iosxr:

```
rule READ-NON-IOSXR
 path              /devices/device
 access-operations read
 action            permit
 when              "not(starts-with(name, 'iosxr-'))"
!
```

### 5.6 `when` in XML init files

```xml
<rule>
  <name>READ-IOS-DEVICES-ONLY</name>
  <path xmlns:ncs="http://tail-f.com/ns/ncs">/ncs:devices/ncs:device</path>
  <access-operations>read</access-operations>
  <action>permit</action>
  <when xmlns:acm="http://tail-f.com/ns/acm">
    starts-with(ncs:name, 'ios-')
  </when>
</rule>

<rule>
  <name>DENY-ALARM-DEVICES-WRITE</name>
  <path xmlns:ncs="http://tail-f.com/ns/ncs">/ncs:devices/ncs:device</path>
  <access-operations>create update delete</access-operations>
  <action>deny</action>
  <when xmlns:acm="http://tail-f.com/ns/acm">
    count(ncs:alarms/ncs:alarm) > 0
  </when>
</rule>
```

---

## Step 6 — RPC / Action Rules

For `exec` access, use `module-name` + `rpc-name` instead of `path`.

### Allow specific RPCs

```
rule PERMIT-SYNC-FROM
 module-name  tailf-ncs
 rpc-name     devices/device/sync-from
 access-operations exec
 action       permit
!
rule DENY-SYNC-TO
 module-name  tailf-ncs
 rpc-name     devices/device/sync-to
 access-operations exec
 action       deny
!
rule PERMIT-CHECK-SYNC
 module-name  tailf-ncs
 rpc-name     devices/device/check-sync
 access-operations exec
 action       permit
!
rule PERMIT-COMPARE-CONFIG
 module-name  tailf-ncs
 rpc-name     devices/device/compare-config
 access-operations exec
 action       permit
!
```

### Block all RPCs except a known list (deny-all catch-all)

```
rule DENY-ALL-RPC
 module-name  *
 rpc-name     *
 access-operations exec
 action       deny
!
```

> Place this as the **last rule** in the list after explicit permit rules.

---

## Step 7 — Set Default Policies

```
config
 nacm read-default   deny
 nacm write-default  deny
 nacm exec-default   deny
commit
```

---

## Step 8 — Common Patterns

### Read-only operator (full tree, no writes, no exec)

```
nacm rule-list READ-ONLY-POLICY
 group [ READ-ONLY-OPS ]
 rule ALLOW-ALL-READ
  path              /
  access-operations read
  action            permit
 !
 rule DENY-ALL-WRITE
  path              /
  access-operations create update delete
  action            deny
 !
 rule DENY-ALL-EXEC
  module-name       *
  rpc-name          *
  access-operations exec
  action            deny
 !
!
```

### Service owner — full access to one service type, read-only elsewhere

```
nacm rule-list NTP-OWNER-POLICY
 group [ NTP-TEAM ]
 rule FULL-ACCESS-NTP-SERVICE
  path              /services/ntp-min-service
  access-operations *
  action            permit
 !
 rule READ-DEVICES
  path              /devices/device
  access-operations read
  action            permit
 !
 rule DENY-EVERYTHING-ELSE
  path              /
  access-operations *
  action            deny
 !
!
```

### Device-region isolation using XPath `starts-with`

EMEA operators can only touch devices whose names start with `emea-`:

```
nacm rule-list EMEA-DEVICE-ACCESS
 group [ EMEA-OPS ]
 rule READ-EMEA-DEVICES
  path              /devices/device
  access-operations read
  action            permit
  when              "starts-with(name, 'emea-')"
 !
 rule WRITE-EMEA-DEVICES
  path              /devices/device
  access-operations create update delete
  action            permit
  when              "starts-with(name, 'emea-')"
 !
 rule DENY-NON-EMEA-DEVICES
  path              /devices/device
  access-operations *
  action            deny
 !
!
```

---

## Step 9 — Full XML Init File Example

**`init/nacm-rules.xml`**

```xml
<config xmlns="http://tail-f.com/ns/config/1.0">
  <nacm xmlns="urn:ietf:params:xml:ns:yang:ietf-netconf-acm">
    <enable>true</enable>
    <read-default>deny</read-default>
    <write-default>deny</write-default>
    <exec-default>deny</exec-default>

    <groups>
      <group>
        <name>NOC-OPERATORS</name>
        <user-name>alice</user-name>
        <user-name>bob</user-name>
      </group>
      <group>
        <name>NTP-TEAM</name>
        <user-name>ntp-admin</user-name>
      </group>
    </groups>

    <!-- NOC read-only: read all devices, no writes, sync-from / check-sync only -->
    <rule-list>
      <name>NOC-READ-ONLY</name>
      <group>NOC-OPERATORS</group>

      <!-- Read all devices -->
      <rule>
        <name>ALLOW-READ-DEVICES</name>
        <path xmlns:ncs="http://tail-f.com/ns/ncs">/ncs:devices</path>
        <access-operations>read</access-operations>
        <action>permit</action>
      </rule>

      <!-- Hide passwords even within the readable subtree -->
      <rule>
        <name>DENY-AUTHGROUP-PASSWORDS</name>
        <path xmlns:ncs="http://tail-f.com/ns/ncs">
          /ncs:devices/ncs:authgroups/ncs:group/ncs:umap/ncs:remote-password
        </path>
        <access-operations>read</access-operations>
        <action>deny</action>
      </rule>

      <!-- Only IOS devices can be read with this rule (when filter example) -->
      <rule>
        <name>READ-IOS-ONLY</name>
        <path xmlns:ncs="http://tail-f.com/ns/ncs">/ncs:devices/ncs:device</path>
        <access-operations>read</access-operations>
        <action>permit</action>
        <when xmlns:acm="http://tail-f.com/ns/acm">
          starts-with(ncs:name, 'ios-')
        </when>
      </rule>

      <!-- Allow sync-from and check-sync RPCs -->
      <rule>
        <name>ALLOW-SYNC-FROM</name>
        <module-name>tailf-ncs</module-name>
        <rpc-name>devices/device/sync-from</rpc-name>
        <access-operations>exec</access-operations>
        <action>permit</action>
      </rule>
      <rule>
        <name>ALLOW-CHECK-SYNC</name>
        <module-name>tailf-ncs</module-name>
        <rpc-name>devices/device/check-sync</rpc-name>
        <access-operations>exec</access-operations>
        <action>permit</action>
      </rule>

      <!-- Deny everything else -->
      <rule>
        <name>DENY-ALL-WRITE</name>
        <path>/</path>
        <access-operations>create update delete</access-operations>
        <action>deny</action>
      </rule>
      <rule>
        <name>DENY-ALL-EXEC</name>
        <module-name>*</module-name>
        <rpc-name>*</rpc-name>
        <access-operations>exec</access-operations>
        <action>deny</action>
      </rule>
    </rule-list>

    <!-- NTP team: full access to ntp-min-service, read-only on devices -->
    <rule-list>
      <name>NTP-OWNER-POLICY</name>
      <group>NTP-TEAM</group>

      <rule>
        <name>FULL-ACCESS-NTP-SERVICE</name>
        <path xmlns:ncs="http://tail-f.com/ns/ncs">
          /ncs:services/ncs:ntp-min-service
        </path>
        <access-operations>*</access-operations>
        <action>permit</action>
      </rule>

      <rule>
        <name>READ-DEVICES</name>
        <path xmlns:ncs="http://tail-f.com/ns/ncs">/ncs:devices/ncs:device</path>
        <access-operations>read</access-operations>
        <action>permit</action>
      </rule>

      <rule>
        <name>DENY-EVERYTHING-ELSE</name>
        <path>/</path>
        <access-operations>*</access-operations>
        <action>deny</action>
      </rule>
    </rule-list>

  </nacm>
</config>
```

Load it:

```bash
ncs_load -l -m init/nacm-rules.xml
```

---

## Step 10 — Verify and Test

### Check running NACM config

```
show running-config nacm
```

### Test as a specific user

```bash
ncs_cli -u alice -C
show devices device ios-0 config        # should succeed (read permit)
config
 devices device ios-0 config            # should fail (write deny)
```

### Inspect the audit log for denied events

```bash
tail -f $NCS_LOG_DIR/audit.log | grep -i "nacm\|denied"
```

Each denied access logs: `user`, `path accessed`, `operation`, and `rule that matched`.

---

## XPath Quick Reference

| Expression | Meaning |
|---|---|
| `/devices/device` | All device list instances |
| `/devices/device[name='ios-0']` | Only the device named `ios-0` |
| `/services/ntp-min-service[name='PROD']` | Only the PROD NTP service instance |
| `/devices/device/config` | Config subtree of every device |
| `/devices/authgroups/group/umap/remote-password` | Password leaf inside every authgroup user map |
| `/devices/device/ssh/host-key` | SSH host keys of every device |
| `starts-with(name, 'ios-')` | `when` — name begins with `ios-` |
| `not(starts-with(name, 'lab-'))` | `when` — name does NOT begin with `lab-` |
| `contains(name, 'PROD')` | `when` — name contains the string `PROD` |
| `name = 'ios-0' or name = 'ios-1'` | `when` — match two specific instances |
| `count(alarms/alarm) > 0` | `when` — device has at least one alarm |
| `state/oper-state = 'enabled'` | `when` — only in-service devices |
| `starts-with(name, 'ios-') and state/oper-state = 'enabled'` | `when` — IOS and in-service |
| `string-length(state/last-transaction-id) > 0` | `when` — device has been synced at least once |

---

## Troubleshooting

| Symptom | Check |
|---|---|
| User can't read anything | `read-default` is `deny` — add a permit rule or change default |
| Rule seems to be ignored | Rules are evaluated **top-down** — a broader deny above may match first |
| Key predicate not matching | Verify the exact key value with `show devices device <tab>` |
| `when` not firing | Confirm `tailf-acm` extension support; check that XPath references correct leaf names |
| RPC denied unexpectedly | Check `exec-default` and verify an explicit `exec` permit rule for that RPC |
| XML load fails on `path` | Add the correct `xmlns:` prefix declaration on the `<path>` element |
| Namespace errors in XML | Each unique prefix must be declared — one declaration per `<path>` or `<when>` element |

---

## References

- RFC 8341 — Network Configuration Access Control Model (NACM)
- NSO Admin Guide — NACM chapter
- `tailf-acm.yang` — Tail-f XPath `when` extensions
- `ncs_load` man page — CDB XML loading
- XPath 1.0 spec — `starts-with()`, `contains()`, `count()`, `not()`, `string-length()` functions
