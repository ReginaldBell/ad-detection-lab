# Enterprise AD Lab

Reproducible Terraform + Ansible workflow for a local VirtualBox AD lab.

## Prerequisites

- WSL2 Ubuntu with `terraform` and `ansible` installed
- VirtualBox with host-only adapter `vboxnet0`
- ISO files provided via `terraform.tfvars` (not committed)

## 1) Terraform Provisioning

```bash
cd ~/enterprise-ad-lab/terraform
terraform init
terraform validate
terraform plan
terraform apply
```

## 2) Install Ansible Collections

```bash
cd ~/enterprise-ad-lab
ansible-galaxy collection install -r ansible/requirements.yml
```

## 3) Export Credentials (no plaintext secrets in inventory)

```bash
export LAB_DC_ADMIN_PASSWORD='replace-me'
export LAB_WKSTN_PASSWORD='replace-me'
export LAB_SIEM_PASSWORD='replace-me'
# Optional: if unset, LAB_DC_ADMIN_PASSWORD is reused for DSRM
export LAB_DSRM_PASSWORD='replace-me'
```

## 4) Verify Inventory and Connectivity

```bash
cd ~/enterprise-ad-lab
ansible-inventory --list
ansible -m win_ping domain_controllers
ansible -m win_ping workstations
ansible -m ping siem
```

## 5) Promote DC01

```bash
cd ~/enterprise-ad-lab
ansible-playbook ansible/playbooks/01-promote-dc01.yml
```

## Notes

- This repo uses sanitized example values (`example.local`, `10.0.0.0/24`).
- Host-specific credentials are sourced from env vars via `ansible/host_vars/*`.
- Put real ISO paths and network values in untracked `terraform.tfvars`.
