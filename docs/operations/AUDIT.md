# Enterprise AD Detection Lab Operational Audit

**Audit date:** 2026-04-07 to 2026-04-08
**Auditor:** Codex
**Audit type:** Read-only operational validation with live service checks

## Executive Summary

The lab is **functionally operational** and the core detection pipeline is working.
The environment booted successfully, core services were reachable, Wazuh manager and dashboard were active, osTicket was serving successfully, and the live `custom-osticket` log on `siem01` showed successful ticket creation for the documented detection phases.

The lab should be considered **complete but with operational caveats** rather than perfectly production-clean.
The two meaningful caveats observed during audit were:

- the core VMs were initially powered off and required manual startup
- `dc02` was initially powered off and appeared as `Disconnected` in Wazuh until it was started

An additional quality issue remains:

- rule `60122` is still generating noisy ticket activity and should be tuned

## Audit Scope

This audit validated:

- VirtualBox VM inventory and runtime state
- current snapshot lineage for core systems
- live reachability of `siem01`, `ticket01`, and Windows management ports
- live service health for Wazuh manager, Wazuh dashboard, Apache, MySQL, and Wazuh agent
- Wazuh agent registration state
- presence of live osTicket integration wiring on `siem01`
- recent evidence of ticket creation for documented detections

This audit did **not** perform a full fresh attack replay for every phase.

## Overall Assessment

| Area | Result | Notes |
|---|---|---|
| Core VM inventory present | PASS | `dc01`, `dc02`, `wkstn01`, `siem01`, `ticket01`, `gophish01`, `mail01` all exist in VirtualBox |
| Core VM bootability | PASS | `dc01`, `dc02`, `wkstn01`, `siem01`, `ticket01` started successfully |
| Snapshot completion state | PASS | Core systems show current snapshot `phase8-11-complete-2026-04-07` |
| SIEM reachability | PASS | `siem01` reachable on SSH and HTTPS |
| Ticketing reachability | PASS | `ticket01` reachable on SSH and HTTP; HTTP returned `200` |
| SIEM services | PASS | `wazuh-manager` and `wazuh-dashboard` active |
| Ticketing services | PASS | `wazuh-agent`, `apache2`, and `mysql` active |
| Wazuh agent enrollment | PASS with caveat | `dc02` was initially disconnected because it was powered off; returned to `Active` after boot |
| osTicket integration wiring | PASS | `ossec.conf` includes `custom-osticket` integration and expected rule IDs |
| Detection-to-ticket evidence | PASS | `custom-osticket.log` shows successful ticket creation for Phases 8-11 paths |
| Operational cleanliness | PARTIAL | `60122` still shows noise/duplicate behavior |

## Live Evidence Collected

### 1. VirtualBox Runtime State

At the beginning of the audit, `VBoxManage list runningvms` returned no running VMs.
The following core VMs were then started successfully:

- `dc01`
- `dc02`
- `wkstn01`
- `siem01`
- `ticket01`

This confirms the lab is bootable, but also confirms it was not already in a continuously running operational state.

### 2. Snapshot State

The following current snapshots were confirmed:

- `dc01`: `phase8-11-complete-2026-04-07`
- `siem01`: `phase8-11-complete-2026-04-07`
- `ticket01`: `phase8-11-complete-2026-04-07`

`dc02` current snapshot was confirmed as:

- `dc02`: `dc02-wazuh-enrolled`

This supports the claim that the core lab was saved after the Phase 8-11 completion work.

### 3. Network and Service Reachability

The following live checks succeeded after boot:

- `192.168.56.50:22` (`siem01` SSH)
- `192.168.56.50:443` (`siem01` HTTPS)
- `192.168.56.105:22` (`ticket01` SSH)
- `192.168.56.105:80` (`ticket01` HTTP)
- `192.168.56.10:5985` (`dc01` WinRM)
- `192.168.56.20:5985` (`wkstn01` WinRM)

`ticket01` returned HTTP status `200` from the web application.

### 4. Live Linux Host Validation

On `ticket01`, the following services were confirmed active:

- `wazuh-agent`
- `apache2`
- `mysql`

`ost-config.php` was present, and local HTTP returned `200 OK`.

On `siem01`, the following services were confirmed active:

- `wazuh-manager`
- `wazuh-dashboard`

### 5. Wazuh Agent Registry

After booting `dc02`, `agent_control -l` on `siem01` showed:

- `000` `siem01` `Active/Local`
- `001` `DC01` `Active`
- `002` `WKSTN01` `Active`
- `006` `ticket01` `Active`
- `007` `dc02` `Active`

Remaining disconnected agents:

- `004` `gophish01`
- `005` `mail01`

These do not block the core AD detection lab from functioning, but they remain incomplete if they are meant to be part of a larger scenario set.

### 6. osTicket Integration Configuration

Live `siem01` configuration inspection confirmed:

- `custom-osticket` integration blocks exist in `/var/ossec/etc/ossec.conf`
- one integration block includes:
  - `60115`
  - `60122`
  - `91809`
  - `92037`
  - `100209`
  - `100210`
  - `100211`
- a separate integration block includes:
  - `60109`

This matches the expected detection-to-ticket routing design.

### 7. Detection-to-Ticket Evidence

Recent `custom-osticket.log` entries on `siem01` showed successful ticket creation for:

- `60115` account lockout
- `60122` failed logon
- `91809` PowerShell abuse
- `100209` lateral movement
- `100210` explicit credential use
- `100211` scheduled task persistence

Representative timestamps observed:

- `2026-04-07 16:28:50` rule `91809`
- `2026-04-07 16:28:51` rule `100211`
- `2026-04-07 16:34:08` rule `100210`
- `2026-04-07 16:35:03` rule `100209`

This is strong evidence that the documented Phase 8-11 routing is live.

## Findings

### Finding 1: Core lab is operational

**Severity:** Low

The core detection lab stack is functional. The SIEM and ticketing infrastructure were reachable and healthy, the Wazuh manager recognized the expected agents once powered on, and the integration log showed successful ticket creation for the documented detection rules.

### Finding 2: Lab is not maintained in always-on state

**Severity:** Medium

At audit start, the core VMs were powered off. This is not a build failure, but it does mean the lab is not presently operating as an always-available environment.

### Finding 3: `dc02` operational status depends on manual startup

**Severity:** Medium

At audit start, `dc02` was powered off and showed as `Disconnected` in Wazuh. Once started, it returned to `Active`.
This means the earlier documentation claiming `dc02` is active was only conditionally true.

### Finding 4: `60122` alert hygiene remains noisy

**Severity:** Medium

The `custom-osticket.log` still showed duplicate/noisy `60122` ticket creation behavior.
Observed example:

- `2026-04-08 03:00:21` two `60122` ticket creations for `DC01`

This does not break functionality, but it does reduce signal quality and may create analyst fatigue.

### Finding 5: Documentation remains slightly inconsistent

**Severity:** Low

The live state aligns best with `PHASES-8-11-COMPLETION.md`, while some older state documents still reflect an earlier readiness-only posture.
The implementation appears ahead of the documentation cleanup.

## Conclusion

The lab passes a practical operational audit for the core Enterprise AD detection use case.

It is reasonable to describe the lab as:

- **technically complete**
- **operational**
- **validated at the platform level**

It is not yet ideal to describe it as fully polished, because:

- the environment was not already powered on
- `dc02` required startup before Wazuh showed full health
- `60122` still needs tuning

## Recommended Remediation

1. Update the primary state document so it matches the actual current completed status.
2. Decide whether `dc02` should be considered required for baseline lab readiness; if yes, keep it powered on before demonstrations or testing.
3. Tune `60122` routing to reduce duplicate/noisy osTicket creation.
4. If the lab will be presented or handed off, capture one final unified âknown goodâ audit-backed state document referencing this file.

## Final Verdict

**Audit verdict: PASS with operational caveats**

The core lab works and the detection pipeline is live. The remaining issues are operational polish and signal hygiene, not missing core functionality.
