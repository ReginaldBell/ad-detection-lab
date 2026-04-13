# dc01_register_ticket01_dns.ps1
# Run on dc01 as Domain Admin after ticket01_osticket.yml completes.
# Registers ticket01.corp.techcorp.internal -> 192.168.56.105 with PTR.

$Zone      = "corp.techcorp.internal"
$HostName  = "ticket01"
$IPAddress = "192.168.56.105"

# Forward A record + PTR
Add-DnsServerResourceRecordA `
    -Name        $HostName `
    -ZoneName    $Zone `
    -IPv4Address $IPAddress `
    -CreatePtr `
    -TimeToLive  ([System.TimeSpan]::FromMinutes(15))

# Verify
Resolve-DnsName "$HostName.$Zone" -Type A
Resolve-DnsName $IPAddress        -Type PTR
