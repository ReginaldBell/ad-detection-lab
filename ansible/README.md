# osTicket Ansible Deliverables — Enterprise AD Detection Lab

## Files

| File | Purpose |
|---|---|
| `inventory/hosts.ini` | Lab inventory with new `[ticketing]` group |
| `group_vars/all/vault.yml` | Secret placeholder — **encrypt before committing** |
| `playbooks/ticket01_lamp.yml` | LAMP stack (Apache2, MySQL 8, PHP 8.3) |
| `playbooks/ticket01_osticket.yml` | osTicket v1.18.1 deploy + Wazuh repo/install/enrollment |
| `playbooks/dc01_register_ticket01_dns.ps1` | DNS A+PTR record on dc01 |

## Execution Order

```bash
# 0. Set real passwords in vault.yml, then encrypt
ansible-vault encrypt ansible/group_vars/all/vault.yml

# 1. LAMP stack (~10-15 min)
ansible-playbook -i inventory/hosts.ini playbooks/ticket01_lamp.yml \
  --ask-vault-pass

# 2. osTicket deploy + Wazuh install (~10 min, then browser)
ansible-playbook -i inventory/hosts.ini playbooks/ticket01_osticket.yml \
  --ask-vault-pass

# 3. Complete web installer in browser
#    http://192.168.56.105/osticket/setup/

# 4. Post-install lockdown (run immediately after web installer)
ansible-playbook -i inventory/hosts.ini playbooks/ticket01_osticket.yml \
  --ask-vault-pass --tags post_install

# 5. Register DNS on dc01 (PowerShell, run as Domain Admin)
#    playbooks/dc01_register_ticket01_dns.ps1

# 6. Snapshot
VBoxManage snapshot ticket01 take "osTicket-v1.18.1-baseline" \
  --description "LAMP stack, post-install config, Wazuh agent enrolled"
```

## Quick Verification After Each Phase

**LAMP:**
```bash
ansible ticketing -i inventory/hosts.ini -m shell \
  -a "php -v && apache2 --version && mysql --version" --ask-vault-pass
```

**osTicket:**
```bash
# From any lab VM
curl -sI http://192.168.56.105/osticket/ | head -2
# Expected: HTTP/1.1 200 OK or 302 Found
```

**Post-install lockdown:**
```bash
ansible ticketing -i inventory/hosts.ini -m shell \
  -a "stat -c '%a' /var/www/html/osticket/include/ost-config.php && ls /var/www/html/osticket/setup 2>&1" \
  --ask-vault-pass
# Expected: 644 / No such file or directory
```

## Bugs fixed from original generation

| # | File | Issue | Fix applied |
|---|---|---|---|
| 1 | `ticket01_osticket.yml` | `is directory` Jinja2 test doesn't exist — template error on `unarchive` | Replaced with `stat` pre-check + `when: not upload_dir_stat.stat.exists` |
| 2 | `ticket01_osticket.yml` | `args: creates:` unsupported on `copy` module | Replaced with `stat` pre-check + `when: not ost_config_stat.stat.exists` |
| 3 | Both playbooks | `vars_files: ../group_vars/all/vault.yml` breaks if not run from `ansible/playbooks/` | Removed — Ansible auto-loads `group_vars/all/vault.yml` via inventory path |
| 4 | `ticket01_osticket.yml` | Wazuh tasks silently skipped if agent not pre-installed | Added Wazuh GPG key, apt repo, and `apt install wazuh-agent` before enrollment |
| 5 | `ticket01_osticket.yml` | `apt_key` deprecated on Ubuntu 22.04+ — emits deprecation warning | Replaced with `get_url` + `gpg --dearmor` -> `/etc/apt/trusted.gpg.d/wazuh.gpg` |

## .gitignore additions

```
# Ansible vault — never commit plaintext
ansible/group_vars/all/vault.yml

# Temp files
*.tfplan
*.zip
```
