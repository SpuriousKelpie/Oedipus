param(
    [Parameter(Mandatory=$True)]
    [String[]]$Identity,

    [Parameter(Mandatory=$True)]
    [ValidateSet("Department","Title")]
    [String]$Scope
)

Import-Module ActiveDirectory
Import-Module C:\Users\Administrator\Desktop\Oedipus\Oedipus.psm1 -Force

$Date = Get-Date -UFormat "%d/%m/%Y"

$Post=@"
</section>
<script src='../js/search_candidates.js'></script>
"@

ForEach ($Group in $Identity){

$Head=@"
<!-- Metadata -->
<title>$Group Report</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<meta name='viewport' content='width=device-width, initial-scale=1.0'/>
<meta name='description' content='Report for $Group group'/>
<meta name='author' content='$env:UserName'/>
<!-- CSS and jQuery -->
<link rel='stylesheet' type='text/css' href='../css/styling.css'/>
<script src='../js/jquery_3.4.0.min.js'></script>
"@

$Pre=@"
<!-- Side Panel -->
<ul>
    <li id='heading'>$Group</a></li>
    <li><input type='text' id='search_input' placeholder='Search candidates'></li>
    <li id='footer'>Report generted by <span>$env:UserName</span> for <span>
        $env:UserDNSDomain</span> on <span>$Date</span></li>
</ul>
<!-- Main Section -->
<section>
"@

    if ($Scope -eq "Department"){
        Get-OedipusOutliers -Objects (New-OedipusDataset1 -Identity $Group |
        Sort-Object -Property Counter) |
        ConvertTo-Html -Property Members,Department -Head $Head -PreContent $Pre -PostContent $Post |
        Out-File Reports/$Group.html -Encoding UTF8 -NoClobber
    }

    if ($Scope -eq "Title"){
        Get-OedipusOutliers -Objects (New-OedipusDataset2 -Identity $Group |
        Sort-Object -Property Counter) |
        ConvertTo-Html -Property Members,Title -Head $Head -PreContent $Pre -PostContent $Post |
        Out-File Reports/$Group.html -Encoding UTF8 -NoClobber
    }
}