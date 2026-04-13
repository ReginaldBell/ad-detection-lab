output "ticket01_ip" {
  description = "osTicket VM — assign this IP statically via Netplan after first boot"
  value       = "192.168.56.105"
}

output "lab_summary" {
  value = <<-EOT
    ============================================
     Enterprise AD Detection Lab — VM Summary
    ============================================
     dc01      (Primary DC)     -> 192.168.56.10
     dc02      (Secondary DC)   -> 192.168.56.11
     wkstn01   (Workstation)    -> 192.168.56.20
     siem01    (Wazuh SIEM)     -> 192.168.56.50
     ticket01  (osTicket)       -> 192.168.56.105
    ============================================
  EOT
}
