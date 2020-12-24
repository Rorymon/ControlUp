# ControlUp Resources and Scripts

<b>CU_MorningReport.ps1</b> uses data retrived from ControlUp to produce daily reports. These can be useful to provide data to those who do not have access to ControlUp Insights as well as for tracking some metrics day to day that are currently presented in the ControlUp Console but not in any of the ControlUp Insights dashboards.

<h3>Example of Report</h3>

<img width="1274" alt="Screen Shot 2020-12-24 at 1 28 14 PM" src="https://user-images.githubusercontent.com/7652987/103091390-ea920000-45eb-11eb-9c9d-ae5e2f286978.png">

Above you can see an example of the morning report using the default configuration.

<img width="1274" alt="Screen Shot 2020-12-24 at 1 44 25 PM" src="https://user-images.githubusercontent.com/7652987/103092135-2cbc4100-45ee-11eb-924d-bb95bbabefbe.png">

In this example, you can see some of the colour coding I have included to highlight when VMTools are out of date and to show which machines rebooted the day the report was run.

<h3>Getting Started</h3>

<img width="1234" alt="Screen Shot 2020-12-24 at 12 26 36 PM" src="https://user-images.githubusercontent.com/7652987/103088812-e7931180-45e3-11eb-8c3c-60ff66d19522.png">

You will need to go into the <b>ControlUp Console</b>, navigate to <b>Settings</b> setup an <b>Export Schedule</b>. I recommend outputting to <b>C:\Users\Public\Reports</b> to make things easy. I choose to run an export every morning around 4am. You can set your export to run at any time you'd like.

<img width="929" alt="Screen Shot 2020-12-24 at 12 36 35 PM" src="https://user-images.githubusercontent.com/7652987/103089076-c67ef080-45e4-11eb-833e-fd0c0621ac31.png">

On one of your <b>ControlUp Monitor</b> servers, create the directory <b>C:\Users\Public\Reports</b> and copy <b>CU_MorningReport.ps1</b> to that location.

<img width="454" alt="Screen Shot 2020-12-24 at 12 39 24 PM" src="https://user-images.githubusercontent.com/7652987/103089187-165db780-45e5-11eb-9aff-7445bf6b6b0f.png">

On the same <b>ControlUp Monitor server</b>, create a <b>Scheduled Task</b> and run it every day AFTER the <b>ControlUp Export Schedule</b> has completed. (Give that at least a 10 minute window depending on how large your environment is).

Example:<br/>
<b>Program/script set to:</b> C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe<br/>
<b>Arguments set to:</b> -executionPolicy RemoteSigned -NoLogo -file "C:\Users\Public\Reports\CU_MorningReport.ps1" -primarymon CUMONITOR01.rorymon.com -secondarymon CUMONITOR02.slhnaz.org -deliverygroup "App-V Applications" -emaildist CitrixEngineers@rorymon.com -smtpserver mymail.rorymon.com -emailfrom noreply@rorymon.com -reportdir C:\Users\Public\Reports

You can change these arguments to suit your environment and run the script to see if this report meets you needs.

<img width="1238" alt="Screen Shot 2020-12-24 at 12 53 38 PM" src="https://user-images.githubusercontent.com/7652987/103089805-12329980-45e7-11eb-9ea3-a27f2f7562a7.png">

If you would like to change what metrics the report displays, you can do this. Find the metrics you would like to use in one of the <b>Export Schedule</b> reports.

At the time this was published, examples of just some available metrics include:

```Stress Level	Name	NetBios	Status	Operating System	OS Version	System Type	CPU Logical Processors (OS)	Memory	Uptime	Uptime in days	User Sessions	ICA Sessions Count	Session Disconnection Rate	CPU	Memory Utilization	Disk Queue	Free Space on System Drive	XenApp Load	Avg. Disk Read Time	Avg. Disk Write Time	Net Total	Sessions	XenApp Server Logon Mode	Net Sent	Net Received	Domain DNS	OS Service Pack	Organization	Processes	Install Date```

<img width="920" alt="Screen Shot 2020-12-24 at 12 46 13 PM" src="https://user-images.githubusercontent.com/7652987/103089512-08f4fd00-45e6-11eb-8298-6b6933e62d30.png">

Replace the above lines with the string that contains what you want to report on.

```Import-Csv $primoutput | select "Name", "XD Delivery Group", "XenApp Server Logon Mode","Uptime in Days","Free Space on System Drive","IP Addresses","PVS vDisk File Name","Logon Server","Host Name","VM Tools Version","VM Tools Version State" | Export-Csv -NoTypeInformation -Path $morningreportsdir\Part1.csv
Import-Csv $secoutput | select "Name", "XD Delivery Group", "XenApp Server Logon Mode","Uptime in Days","Free Space on System Drive","IP Addresses","PVS vDisk File Name","Logon Server","Host Name","VM Tools Version","VM Tools Version State" | Export-Csv -NoTypeInformation -Path $morningreportsdir\Part2.csv```

