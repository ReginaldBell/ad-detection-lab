output "dc01_ip" {
  description = "DC01 Primary Domain Controller IP"
  value       = "10.0.0.10"
}

output "dc02_ip" {
  description = "DC02 Secondary Domain Controller IP"
  value       = "10.0.0.11"
}

output "wkstn01_ip" {
  description = "WKSTN01 Victim Workstation IP"
  value       = "10.0.0.20"
}

output "siem01_ip" {
  description = "SIEM01 Wazuh Manager IP"
  value       = "10.0.0.50"
}

output "lab_summary" {
  value = <<-EOT
    ========================================
     Enterprise AD Lab - Network Summary
    ========================================
     DC01    (Primary DC)    -> 10.0.0.10
     DC02    (Secondary DC)  -> 10.0.0.11
     WKSTN01 (Victim box)    -> 10.0.0.20
     SIEM01  (Wazuh SIEM)    -> 10.0.0.50
    ========================================
     Wazuh Dashboard -> http://10.0.0.50
     Domain          -> example.local
    ========================================
  EOT
}
