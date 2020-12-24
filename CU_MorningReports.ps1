<#
.SYNOPSIS
    Generates and sends a custom report showing health of Citrix VDAs in a given Delivery Group.

.DESCRIPTION
    This script takes some info unique to your ControlUp and Citrix environment and produces a custom report. This can useful
    for sharing a healthcheck each morning for a quick glance. It can also be useful as a snapshot in time of the machines in
    your Delivery Groups for latering comparing key metrics like free space, vDisk File Name etc.

.PARAMETER primarymon
  The Fully Qualified Domain Name of your primary ControlUp Monitor. This can be found by clicking on Monitoring Status in the
  top left of the ControlUp Console.
  e.g. CUMonitor01.rorymon.com

.PARAMETER secondarymon
  The Fully Qualified Domain Name of your secondary ControlUp Monitor. This can be found by clicking on Monitoring Status in the
  top left of the ControlUp Console.
  e.g. CUMonitor02.rorymon.com

.PARAMETER deliverygroup
  The name of the Delivery Group you would like to generate a report for.
  e.g. "'Published Shared Desktops'"
 
.PARAMETER emaildist
  The e-mail distribution address you would like to send the e-mail to.
  e.g. citrixengineering@rorymon.com

.PARAMETER smtpServer
  Your organization's SMTP mail address
   e.g. corpmail.rorymon.com

.PARAMETER emailFrom
 The address you would like to have the report appear to be coming from.
 e.g. noreply@rorymon.com

.PARAMETER reportdir
  The path you set in your ControlUp Export Schedule.
  e.g. C:\Users\Public\Reports        

.EXAMPLE
    . .\CU_MorningReport.ps1 -primarymon CUMonitor01.rorymon.com -secondarymon CUMonitor02.rorymon.com -deliverygroup Prod Apps -emaildist citrixengineering@rorymon.com -smtpserver corpmail.rorymon.com -emailfrom noreply@rorymon.com -reportdir C:\Users\Public\Reports

.CONTEXT
    ControlUp
    Citrix

.MODIFICATION_HISTORY

.LINK

.COMPONENT

.NOTES
    Requires ControlUp Export Schedule. Account used for running script will require ability to create a directory & files in Export Schedule output directory.

    Version:        0.1
    Author:         Rory Monaghan
    Creation Date:  1st Dec 2020.
    Purpose:        Created for producing a custom morning report based off data retrieved by ControlUp
#>

Param(
  [Parameter(Mandatory=$True,Position=1)]
   [string]$primarymon,

   [Parameter(Mandatory=$True)]
   [string]$secondarymon,

   [Parameter(Mandatory=$True)]
   [string]$deliverygroup,

   [Parameter(Mandatory=$True)]
   [string]$emaildist,

   [Parameter(Mandatory=$True)]
   [string]$smtpServer,   

    [Parameter(Mandatory=$True)]
   [string]$emailFrom,

    [Parameter(Mandatory=$True)]
   [string]$reportdir

)

$deliverygroup.Trim('"') 

$morningreportsdir = "$reportdir\MorningReports"

If(!(test-path $morningreportsdir))
{
      New-Item -ItemType Directory -Force -Path $morningreportsdir
}

#Creating search for export schedule reports
$monthraw = (get-date).month
$yearraw = (get-date).year
$strmonth = $monthraw.ToString()
$dayraw = Get-Date -Format "dd"
$strday = $dayraw.ToString()
$dateshort = "$strmonth" + "_" + "$strday"

$unctest = $reportdir.TrimStart("C:\")

$primuncpath = "$primarymon\c$\$unctest"
$secuncpath = "$secondarymon\c$\$unctest"

$reportfilename1 = "$primarymon-ControlUp_Machines_$dateshort*.*"
$reportfilename2 = "$secondarymon-ControlUp_Machines_$dateshort*.*"

$searchinfolder = "\\$secuncpath*"

$inputdata = Get-ChildItem -Path $searchinfolder -Filter $reportfilename2 -Recurse | %{$_.FullName}

#Copying scheudled report from secondary monitor server to report directory

Copy-Item $inputdata -Destination $morningreportsdir

$searchinfolder = "\\$primuncpath*"

$inputdata = Get-ChildItem -Path $searchinfolder -Filter $reportfilename1 -Recurse | %{$_.FullName}

#Copying scheudled report from primary monitor server to report directory

Copy-Item $inputdata -Destination $morningreportsdir

#Now to open up both monitor server's reports to filter them and merge the result

$searchreportdir = "$morningreportsdir\*"
$primoutput = "$morningreportsdir\$primarymon.csv"
$secoutput = "$morningreportsdir\$secondarymon.csv"

$primreport = Get-ChildItem -Path $searchreportdir -Filter $reportfilename1 -Recurse | %{$_.FullName}
$secreport = Get-ChildItem -Path $searchreportdir -Filter $reportfilename2 -Recurse | %{$_.FullName}

$import = get-content $primreport
$import | Select-Object -Skip 1 | Set-Content $primoutput

$import = get-content $secreport
$import | Select-Object -Skip 1 | Set-Content $secoutput

Import-Csv $primoutput | select "Name", "XD Delivery Group", "XenApp Server Logon Mode","Uptime in Days","Free Space on System Drive","IP Addresses","PVS vDisk File Name","Logon Server","Host Name","VM Tools Version","VM Tools Version State" | Export-Csv -NoTypeInformation -Path $morningreportsdir\Part1.csv
Import-Csv $secoutput | select "Name", "XD Delivery Group", "XenApp Server Logon Mode","Uptime in Days","Free Space on System Drive","IP Addresses","PVS vDisk File Name","Logon Server","Host Name","VM Tools Version","VM Tools Version State" | Export-Csv -NoTypeInformation -Path $morningreportsdir\Part2.csv

$csv1 = "$morningreportsdir\Part1.csv"
$csv2 = "$morningreportsdir\Part2.csv"

@(Import-Csv $csv1) + @(Import-Csv $csv2) | Export-Csv $morningreportsdir\WorkingDoc.csv -NoTypeInformation

#Now to import the outputted result and only leaving the results for our Delivery Group

$csv = Import-Csv $morningreportsdir\WorkingDoc.csv | where-object {$_.'XD Delivery Group' -match $deliverygroup } | Export-Csv -NoTypeInformation $morningreportsdir\PSDRawControlUpData.csv

#Finally, sorting the report by name

Import-Csv $morningreportsdir\PSDRawControlUpData.csv | sort -Property Name | Export-Csv -Path $morningreportsdir\MorningReport.csv -NoTypeInformation 

#Setting the CSS for the e-mail report
$css = @"
<style>
h1, h5, th { text-align: center; font-family: Segoe UI; }
table { margin: auto; font-family: Segoe UI; box-shadow: 10px 10px 5px #888; border: thin ridge grey; }
th { background: #0046c3; color: #fff; max-width: 400px; padding: 5px 10px; }
td { font-size: 11px; padding: 5px 20px; color: #000; }
tr { background: #b8d1f3; }
tr:nth-child(even) { background: #dae5f4; }
tr:nth-child(odd) { background: #b8d1f3; }
</style>
"@

$emailTo   = "$emaildist"
$excelreport= "$morningreportsdir\MorningReport.csv"

Import-Csv "$morningreportsdir\MorningReport.csv" | Foreach-Object { 
#Checking to validate all VDAs are no longer on an old vDisk and that VMTools are up to date
    foreach ($property in $_.PSObject.Properties)
    {
        if ($property.Value -contains "2K12R2_PSD_09-23-2020.vhdx"){
        $vdiskcheck = "Report has detected machine(s) with 2K12R2_PSD_09-23-2020.vhdx still attached."
        }

         if ($property.Value -contains "Needs Updating"){
        $vmtoolscheck = "Report has detected machine(s) with outdated VMTools that needs updating"
        }
    } 

}

$params = @{
            Column = "VM Tools Version State"
            ScriptBlock = {[double]$args[0] -gt [double]$args[9]}
        }

If(($daycheck = "") -and ($vdiskcheck ="") -and ($vmtoolscheck = "")){

}
else{
$emailSubject    = "$deliverygroup Morning Report"
$html= Import-CSV "$morningreportsdir\MorningReport.csv" | ConvertTo-Html -PreContent "<h1>$deliverygroup Morning Report</h1>`n<h5>Generated on $(Get-Date)</h5>`n<h4>$daycheck</h4>`n<h4>$vdiskcheck</h4>`n<h4>$vmtoolscheck</h4>" -Head $css -Body "Some VDAs may have an uptime greater than 7 days. This could be expected. Please review the report."

$vmtools =  $html | ForEach {
    
    $PSItem -replace "<td>Needs Updating</td>", "<td style='background-color:#FF8080'>Needs Updating</td>"
}   

$vdisk = $vmtools | ForEach {
 
    $PSItem -replace "<td>2K12R2_PSD_09-23-2020.vhdx</td>", "<td style='background-color:#FF8080'>2K12R2_PSD_09-23-2020.vhdx</td>"
}  

$poweredoff = $vdisk | ForEach {
 
    $PSItem -replace "<td>0.00</td>", "<td style='background-color:#808080'>Powered Off</td>"
}

$justbooted = $poweredoff | ForEach {

    $PSItem -replace "<td>-1.00</td>", "<td style='background-color:#008000'>Rebooted Today</td>"

}

$uptimeexceeded = $justbooted | ForEach {

 $PSItem -replace "<td>8.00</td>", "<td style='background-color:#FF8080'>8.00</td>"

}

$uptimeexceededagain = $uptimeexceeded | ForEach {
$PSItem -replace "<td>9.00</td>", "<td style='background-color:#FF8080'>9 days</td>"
}
#Doing a check to see if uptime exceeds 7 days. After a few days past the 7 days, we stop highlighting.
$uptimeexceededagain | Out-File "$morningreportsdir\MorningReport.html"

}

$resultsHTM = "$morningreportsdir\MorningReport.html"

$mailMessageParameters = @{
From       = $emailFrom
To         = $emailTo
Subject    = $emailSubject
SmtpServer = $smtpServer
Body       = (gc $resultsHTM) | Out-String
Attachment = $excelreport
}

Send-MailMessage @mailMessageParameters -BodyAsHtml

Remove-Item $morningreportsdir\*
