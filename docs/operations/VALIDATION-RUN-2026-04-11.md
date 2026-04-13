# Validation Run - 2026-04-11

## Scope

Full lifecycle validation of the VirtualBox lab:

1. Recommendation plan
2. Controlled implementation
3. Operational audit
4. Snapshot decision gate

## Baseline

- Start time: `2026-04-11T12:03:17.5718960-05:00`
- Runtime source of truth: VirtualBox + guest-level command checks
- Documentation references:
  - `docs/01-architecture.md`
  - `docs/05-active-directory-setup.md`
  - `docs/operations/LAB-STATE.md`
  - `docs/operations/LAB-COMPLETE.md`

## Baseline Findings

- All 7 VMs exist and are running.
- Documentation is internally inconsistent on at least:
  - `dc02` IP (`192.168.56.102` vs `192.168.56.11`)
  - `siem01` IP (`192.168.56.103` vs `192.168.56.50`)
  - snapshot expectations for `gophish01` and `mail01`
- `dc02` current snapshot is not aligned with the documented latest coordinated set.
- AD replication is broken from `dc02`.
- Multiple hostnames drift from documented names.

## Recommendation Plan

| Priority | Action Required | Expected Outcome | Risk If Not Addressed |
|---|---|---|---|
| P1 | Align `dc02` to the documented latest coordinated snapshot set and re-validate replication | Restores the best-known matching state for the replica DC; may resolve replication drift | AD remains inconsistent; detections and identity state continue to diverge |
| P1 | Re-validate Wazuh manager, agent registry, and ticket pipeline after `dc02` alignment | Confirms SOC pipeline still works after identity-state correction | Silent monitoring failure after AD-side changes |
| P2 | Reconcile authoritative documentation for VM IPs, hostnames, and snapshot lineage | Removes operator ambiguity and broken runbooks | Future changes continue to introduce drift |
| P2 | Review undocumented `Domain Admins` memberships (`svc_healthcheck*`) before removal | Clarifies whether privilege drift is intentional or erroneous | Possible privileged persistence remains undetected |
| P3 | Normalize non-critical hostname and extra-IP drift (`ticket01`, `wkstn01`) after core AD health is restored | Improves operational clarity and reduces troubleshooting overhead | Continued operator confusion, but not immediate outage |

## Change Log

| Timestamp | System | Change | Before | After | Validation |
|---|---|---|---|---|---|
| `2026-04-11T12:03:17-05:00` | `dc02` | Baseline capture | Current snapshot `pre-shutdown-2026-04-08_22-17-00`; runtime IP `192.168.56.102` | No change | Confirmed snapshot drift from documented latest coordinated set |
| `2026-04-11T12:04-05:00` | `dc02` | Safety snapshot | No validation-run safety point | `pre-validation-safety-2026-04-11_12-03-44` created | Snapshot completed successfully in VirtualBox |
| `2026-04-11T12:05-12:07-05:00` | `dc02` | Shutdown for restore | VM ignored ACPI shutdown for 3 minutes | Hypervisor power-off used | VM reached `poweroff` state |
| `2026-04-11T12:07-12:08-05:00` | `dc02` | Restore to documented latest coordinated snapshot | Current snapshot `pre-shutdown-2026-04-08_22-17-00` | Current snapshot `session7-complete-2026-04-08` | VM restarted; runtime IP still `192.168.56.102` |
| `2026-04-11T12:08-12:09-05:00` | `siem01` | Post-restore monitoring validation | Agent registry previously showed all agents active | `dc02` active, `DC01` later transitioned to disconnected | Wazuh manager/dashboard/indexer healthy; agent fleet no longer fully healthy |

## Audit Notes

- No destructive rollback is performed without a safety snapshot.
- Validation order: network -> identity -> services -> security -> monitoring.
- Monitoring gap remains after implementation:
  - `DC01` disconnected from Wazuh at `2026-04-11T17:08:49+0000`
- Decision gate result: `NOT ALIGNED`
- Final-state snapshot creation is not authorized for this run.
