# Enterprise AD Detection Lab Phase Plan

Recovered on 2026-04-11 from surviving project artifacts. This is a reconstructed
planning document based on preserved session state, `LAB-COMPLETE.md`,
`HANDOFF.md`, and Claude memory artifacts.

---

## Objective

Build a self-contained Enterprise Active Directory detection lab where realistic
Windows attack activity is detected by Wazuh and automatically routed into
osTicket, with the phishing arc available as a separate extension path.

---

## Core Success Criteria

- Domain infrastructure is stable and reachable.
- Windows event telemetry reaches `siem01`.
- Wazuh detections exist for target attack phases.
- Matching detections create osTicket tickets automatically.
- Documentation and snapshots preserve a known-good state.

---

## Canonical Lab Scope

### Core infrastructure

- `dc01`: primary domain controller, DNS, DHCP
- `dc02`: secondary domain controller
- `wkstn01`: domain workstation and attack simulation box
- `siem01`: Wazuh manager/dashboard
- `ticket01`: osTicket platform

### Extended infrastructure

- `gophish01`: phishing platform
- `mail01`: SMTP/IMAP relay for phishing scenarios

---

## Phase Status

| Phase | Area | Status | Notes |
|---|---|---|---|
| 4 | Failed logon / lockout | Complete | Rules `60122` and `60115` live |
| 5 | New user creation | Complete | Rule `60109` live |
| 6 | Snapshot and infrastructure stabilization | Complete | Known-good snapshots documented |
| 7 | Agent and telemetry fixes | Complete | 4740 and Sysmon collection issues resolved |
| 8 | PowerShell abuse | Complete | Routed via rule `91809` |
| 9 | SMB lateral movement | Complete | Routed via `92037`/custom `100209` |
| 10 | Explicit credential use | Complete | Routed via custom `100210` |
| 11 | Scheduled task persistence | Complete | Routed via custom `100211` |
| 12 | Documentation sync | Complete | LAB-STATE.md updated for Phases 8-11 |
| 13 | 60122 signal cleanup | Complete | `allowed_agents: {DC01, dc02}` confirmed deployed — WKSTN01 noise suppressed |
| 14 | Phishing arc online | Complete | gophish01 + mail01 booted, Wazuh agents Active, Postfix running, snapshots taken |
| 15 | Phishing detection arc | In Progress | GoPhish/mail chain present — detection rules not yet built |
| 16 | Credential harvest detection | Planned | Follow-on to phishing telemetry |
| 17 | Kerberoasting detection | Planned | Custom rule path expected (Event 4769 + RC4 filter) |
| 18 | Pass-the-Hash detection | Planned | Correlation-heavy future work |

---

## Completed Detection Pipeline

The following detections are documented as live and ticketed:

- Phase 4: failed logon via `60122`
- Phase 4: account lockout via `60115`
- Phase 5: user creation via `60109`
- Phase 8: PowerShell abuse via `91809`
- Phase 9: lateral movement via `100209`
- Phase 10: explicit credential use via `100210`
- Phase 11: scheduled task persistence via `100211`

---

## Remaining Build Track

### Track 1: maintain the known-good AD lab

- Keep VM snapshots aligned with documented state.
- Preserve Wazuh agent enrollment and event-channel coverage.
- Reduce noisy ticketing, especially around `60122`.
- Keep `HANDOFF.md`, `LAB-STATE.md`, and audit docs synchronized.

### Track 2: phishing detection arc

- Ingest GoPhish logs into Wazuh.
- Ingest Postfix/mail telemetry into Wazuh.
- Create phishing-specific help topics in osTicket.
- Add detection coverage for send, click, and submit events.

### Track 3: advanced credential abuse detections

- Kerberoasting (`4769`, custom rule path expected)
- Pass-the-Hash / NTLM abuse correlation
- Additional AD lateral movement and persistence coverage

---

## Execution Order

1. Verify baseline VM reachability and agent health.
2. Preserve or refresh snapshots before risky changes.
3. Validate detections with small, controlled repro steps.
4. Confirm Wazuh alerts in `alerts.json`.
5. Confirm osTicket ticket creation in `custom-osticket.log`.
6. Update state docs after each successful milestone.

---

## Constraints And Lessons Learned

- Prefer real domain-auth events over local or cached-credential activity.
- Use current Windows Event Channel rule IDs, not legacy `msauth` IDs.
- Treat WSL routing and host WinRM setup as prerequisites, not optional steps.
- Expect some detections to require custom rules or correlation rather than a
  single built-in Wazuh rule.

---

## Reference Documents

- `LAB-STATE.md`: full chronological state log
- `LAB-CONTEXT.md`: quick reference and topology
- `HANDOFF.md`: operational gotchas and execution guidance
- `LAB-COMPLETE.md`: current end-state reference
- `PHASES-8-11-COMPLETION.md`: validation details for Phases 8-11
