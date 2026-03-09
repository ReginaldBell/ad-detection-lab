# Screenshots

Drop your Wazuh alert screenshots and lab evidence here.

## Naming Convention

Use these filenames to match the references in the detection docs:

| Filename | What to capture |
|---|---|
| `wazuh-kerberoasting-alert.png` | Wazuh dashboard showing Rule 100001 firing (EventID 4769, RC4 encryption type) |
| `eventid-4769.png` | Windows Event Viewer — Security log, EventID 4769 detail |
| `eventid-4625.png` | Windows Event Viewer — Security log, EventID 4625 (failed logon) detail |
| `wazuh-password-spray-alert.png` | Wazuh dashboard showing Rule 100002 firing |
| `wazuh-privilege-escalation-alert.png` | Wazuh dashboard showing Rule 100003 firing (4728, Domain Admins) |
| `wazuh-lateral-movement-alert.png` | Wazuh dashboard showing Rule 100004 firing (4648) |
| `wazuh-rogue-account-alert.png` | Wazuh dashboard showing Rule 100005 firing (4720) |
| `wazuh-agents-active.png` | Wazuh Agents page showing dc01, dc02, wkstn01 as Active |
| `ad-ou-structure.png` | AD Users and Computers showing Tier0/Tier1/Tier2 OU structure |
| `virtualbox-vms.png` | VirtualBox Manager showing all 4 lab VMs running |

## Tips for Good Screenshots

- Use **Full HD (1920×1080)** or higher resolution
- In Wazuh: expand the alert detail panel before screenshotting to show all fields
- Annotate screenshots (red boxes, arrows) using [Greenshot](https://getgreenshot.org/) or Windows Snipping Tool
- Show the **timestamp** in every Wazuh screenshot — it proves the event is real

## Embedding Screenshots in Docs

To reference a screenshot from a markdown file:

```markdown
![Kerberoasting Alert](../screenshots/wazuh-kerberoasting-alert.png)
```
