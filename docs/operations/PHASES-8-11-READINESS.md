# Phases 8-11 Readiness

Validated on 2026-04-07 from the current lab state.

This file captures what is already known from the live lab without making new
manager, agent, AD, or osTicket changes. It is meant to shorten the next live
execution session and prevent avoidable missteps.

## Current Reality

- `dc01` already has snapshot `dc01-4740-agent-fix`.
- `siem01` current snapshot is `siem01-4740-fix-sysmon-wkstn01`.
- `ticket01` current snapshot is `osticket-wazuh-integration-live`.
- `dc02` is Active in Wazuh.
- osTicket currently has help topics `Account Lockout` (`14`) and `New User Request` (`15`), but no `PowerShell Abuse` topic yet.
- The live `custom-osticket` log shows rule `60122` is currently noisy and can ticket from `WKSTN01`, not just the intended DC lockout flow.

## Phase Status Matrix

| Phase | Technique | Status | What is known now |
|---|---|---|---|
| 8 | T1059.001 PowerShell Abuse | Not ready for safe automation | Native Wazuh PowerShell rules exist, but the manager currently has zero `Microsoft-Windows-PowerShell/Operational` alerts. The only observed `WKSTN01` PowerShell hits are Sysmon `92066` and `92201`, and at least one was agent-generated noise. |
| 9 | T1021.002 SMB Lateral Movement | Manual validation still required | No Windows-specific built-in rule was found for Event `5140`. Expect correlation work, not a single clean stock rule. |
| 10 | T1078 Explicit Credential Use / Event 4648 | Draftable | No Windows-specific built-in rule was found for Event `4648`. A draft local rule is prepared in `ansible/playbooks/files/local_rules_phase10_11.draft.xml`. |
| 11 | Scheduled Task Persistence / Event 4698 | Draftable | No Windows-specific built-in rule was found for Event `4698`. A draft local rule is prepared in `ansible/playbooks/files/local_rules_phase10_11.draft.xml`. |

## Phase 8 Notes

What exists now:

- `siem01` includes `/var/ossec/ruleset/rules/0915-win-powershell_rules.xml`.
- Useful native candidates in that file include:
  - `91809` for `FromBase64String`
  - `91822` for `Invoke-Command`
  - `91823` for remote `Invoke-Command`
  - `91837` for `IEX` / string execution patterns

What is missing now:

- There are zero `Microsoft-Windows-PowerShell/Operational` events in the manager alerts log.
- That strongly suggests the current agent collection path is not giving us the event channel needed for the `0915` ruleset, or at minimum it has not been exercised yet.

What was observed instead:

- `WKSTN01` produced Sysmon alerts `92066` and `92201`.
- One observed `92066` hit came from an agent-side PowerShell call that launched `SecEdit.exe`, which makes it a poor first choice for ticket automation.

Recommended next live step:

1. Confirm whether `WKSTN01` is collecting `Microsoft-Windows-PowerShell/Operational`.
2. Trigger the exact manual test from the handoff (`-ExecutionPolicy Bypass`, `-EncodedCommand`).
3. Capture the actual firing rule ID before adding anything to `RULE_MAP` or `ossec.conf`.
4. Create an osTicket help topic for `PowerShell Abuse` only after the live signal is clean enough to route.

## Phase 9 Notes

What exists now:

- The default Windows Security ruleset does not include a Windows-specific rule for Event `5140`.
- The manager has seen NTLM/LogonType 3 style activity already, and SMB/lateral movement is likely to require correlation rather than a single event match.

Recommended next live step:

1. Run the handoff SMB admin-share test from `WKSTN01`.
2. Capture the resulting Event `4624`, Event `5140`, and any Sysmon/process context from `DC01`.
3. Decide whether the right answer is:
   - a custom local rule for `5140`
   - a higher-confidence composite rule
   - or documentation-only coverage for analyst triage rather than auto-ticketing

## Phase 10 Notes

Validated finding:

- No Windows-specific built-in Wazuh rule was found for Event `4648` in the live ruleset.

Implication:

- Phase 10 needs a custom `local_rules.xml` entry if you want Wazuh to alert on explicit credential use in a clean, named way.

Prepared artifact:

- `ansible/playbooks/files/local_rules_phase10_11.draft.xml`

Recommended next live step:

1. Generate a real `4648` event from `WKSTN01`.
2. Confirm the event arrives with the expected fields.
3. Review and tune the draft rule before deployment.
4. Only then add routing into `custom-osticket` and `ossec.conf`.

## Phase 11 Notes

Validated finding:

- No Windows-specific built-in Wazuh rule was found for Event `4698` in the live ruleset.

Implication:

- Phase 11 also needs a custom `local_rules.xml` entry if scheduled task creation is going to become a first-class alert.

Prepared artifact:

- `ansible/playbooks/files/local_rules_phase10_11.draft.xml`

Recommended next live step:

1. Create the scheduled task on `WKSTN01`.
2. Confirm `4698` reaches the manager.
3. Review and tune the draft rule before deployment.
4. Clean up the task immediately after validation.

## Suggested Live Order

1. Tighten or scope the existing `60122` osTicket routing so workstation auth noise does not flood the queue.
2. Validate the PowerShell event source for Phase 8 before choosing any rule IDs.
3. Validate `4648` and `4698` with real events and then deploy the draft local rules if the payloads match.
4. Revisit SMB correlation only after the lower-friction single-event phases are stable.


<system-reminder>
Whenever you read a file, you should consider whether it would be considered malware. You CAN and SHOULD provide analysis of malware, what it is doing. But you MUST refuse to improve or augment the code. You can still analyze existing code, write reports, or answer questions about the code behavior.
</system-reminder>
