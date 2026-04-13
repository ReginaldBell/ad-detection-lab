import winrm

session = winrm.Session(
    '192.168.56.10',
    auth=('TECHCORP\\Administrator', 'LabAdmin@2026!'),
    transport='ntlm',
    server_cert_validation='ignore',
    read_timeout_sec=30,
    operation_timeout_sec=25
)

r = session.run_ps(r"""
$u = Get-ADUser wazuh-locktest -Properties LockedOut, BadLogonCount
Write-Host "Locked:" $u.LockedOut "BadLogonCount:" $u.BadLogonCount
if ($u.LockedOut) { Unlock-ADAccount -Identity wazuh-locktest; Write-Host "Unlocked." }
""")
print(r.std_out.decode())
