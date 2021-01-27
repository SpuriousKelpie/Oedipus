function New-Dataset1{
    <#
    .SYNOPSIS
        Returns a collection of objects for the Get-Outliers function.
    .DESCRIPTION
        Gets all user objects in the specified group and then groups them together
        into individual custom objects based on their department attribute. Each
        custom object maintains a count of its users. These counters are used as
        the dataset for the Get-Outliers function.
    .PARAMETER Identity
        Specifies the Active Directory group object.
    .EXAMPLE
        New-Dataset1 -Identity Executives_All_Staff
    .LINK
        https://github.com/SpuriousKelpie/Oedipus
    #>

    [CmdletBinding()]

    Param(
        [Parameter(ValueFromPipeline=$True, Mandatory=$True)]
        [String]$Identity
    )

    Begin{
        Write-Verbose "[BEGIN  ] Initializing variables."

        Try{
            $Members = Get-ADGroupMember -Identity $Identity -Recursive | Get-ADUser -Properties UserPrincipalName,Department | Select UserPrincipalName,Department
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Host "[ERROR  ] $Identity object not found." -ErrorAction Stop
        }

        $DepartmentCounter = @{}
        $DepartmentMembers = @{}
        $Objects = @()
        $Index = ""
    }

    Process{
        Write-Verbose "[PROCESS] Populating hash tables."
        foreach ($Member in $Members){
            if ($DepartmentCounter.ContainsKey($Member.Department)){
                Write-Verbose "[PROCESS] Key-value pair exists for: $($Member.Department)."
                $DepartmentCounter[$Member.Department]++
                $DepartmentMembers[$Member.Department] += $Member.UserPrincipalName
            }
            else{
                Write-Verbose "[PROCESS] Key-value pair doesn't exist for $($Member.Department)."
                $DepartmentCounter.Add($Member.Department, 0)
                $DepartmentCounter[$Member.Department]++
                $DepartmentMembers.Add($Member.Department, @())
                $DepartmentMembers[$Member.Department] += $Member.UserPrincipalName
            }
        }
    }

    End{
        foreach ($Pair in $DepartmentCounter.GetEnumerator()){
            Write-Verbose "[END    ] Creating custom object for: $($Pair.Name)."
            $Index = $Pair.Name
            $Properties = [ordered]@{"Department" = $Pair.Name
                                     "Counter" = $Pair.Value
                                     "Members" = [string]$DepartmentMembers[$Index]
                                     "Flagged" = 0}
            $Objects += New-Object -TypeName PSObject -Property $Properties
        }
        Write-Verbose "[END    ] Outputting $($Objects.Count) custom objects."
        Write-Output $Objects
    }
}

function New-Dataset2{
    <#
    .SYNOPSIS
        Returns a collection of objects for the Get-Outliers function.
    .DESCRIPTION
        Gets all user objects in the specified group and then groups them together
        into individual custom objects based on their job title attribute. Each
        custom object maintains a count of its users. These counters are used as
        the dataset for the Get-Outliers function.
    .PARAMETER Identity
        Specifies the Active Directory group object.
    .EXAMPLE
        New-Dataset2 -Identity Executives_All_Staff
    .LINK
        https://github.com/SpuriousKelpie/Oedipus
    #>

    [CmdletBinding()]

    Param(
        [Parameter(ValueFromPipeline=$True, Mandatory=$True)]
        [String]$Identity
    )

    Begin{
        Write-Verbose "[BEGIN  ] Initializing variables."

        Try{
            $Members = Get-ADGroupMember -Identity $Identity -Recursive | Get-ADUser -Properties UserPrincipalName,Title | Select UserPrincipalName,Title
        }
        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Host "[ERROR  ] $Identity object not found." -ErrorAction Stop
        }

        $TitleCounter = @{}
        $TitleMembers = @{}
        $Objects = @()
        $Index = ""
    }

    Process{
        Write-Verbose "[PROCESS] Populating hash tables."
        foreach ($Member in $Members){
            if ($TitleCounter.ContainsKey($Member.Title)){
                Write-Verbose "[PROCESS] Key-value pair exists for: $($Member.Title)."
                $TitleCounter[$Member.Title]++
                $TitleMembers[$Member.Title] += $Member.UserPrincipalName
            }
            else{
                Write-Verbose "[PROCESS] Key-value pair doesn't exist for $($Member.Title)."
                $TitleCounter.Add($Member.Title, 0)
                $TitleCounter[$Member.Title]++
                $TitleMembers.Add($Member.Title, @())
                $TitleMembers[$Member.Title] += $Member.UserPrincipalName
            }
        }
    }

    End{
        foreach ($Pair in $TitleCounter.GetEnumerator()){
            Write-Verbose "[END    ] Creating custom object for: $($Pair.Name)."
            $Index = $Pair.Name
            $Properties = [ordered]@{"Title" = $Pair.Name
                                     "Counter" = $Pair.Value
                                     "Members" = [string]$TitleMembers[$Index]
                                     "Flagged" = 0}
            $Objects += New-Object -TypeName PSObject -Property $Properties
        }
        Write-Verbose "[END    ] Outputting $($Objects.Count) custom objects."
        Write-Output $Objects
    }
}

function Get-Outliers{
    <#
    .SYNOPSIS
        Returns outlier objects from New-Dataset input.
    .DESCRIPTION
        Finds the interquartile range of the ordered custom objects and outputs
        objects that have been classed as outliers.
    .PARAMETER Objects
        Specifies the collection of objects to be processed.
    .EXAMPLE
        Get-Outliers -Objects (New-Dataset1 -I $Identity | Sort -Property Counter)
        Get-Outliers -Objects (New-Dataset2 -I $Identity | Sort -Property Counter)
    .LINK
        https://github.com/SpuriousKelpie/Oedipus
    #>

    [CmdletBinding()]

    Param(
        [Parameter(ValueFromPipeline=$True, Mandatory=$True)]
        [PSCustomObject[]]$Objects
    )

    Begin{
        Write-Verbose "[BEGIN  ] Initializing variables."
        $LowerPortion = @()
        $UpperPortion = @()
        $Q1Value1
        $Q1Value2
        $Q1
        $Q2Value1
        $Q2Value2
        $Q2
        $Q3Value1
        $Q3Value2
        $Q3
        $LastItem
        $IQR
        $Counter
    }

    Process{
        # Check dataset contains >1 objects
        if ($Objects.Count -le 1){
            Write-Host "[ERROR  ] Not enough object in dataset." -ErrorAction Stop
        }

        # Find the median
        if ($Objects.Count % 2){
            Write-Verbose "[PROCESS] Dataset is odd numbered."
            $Q2 = $Objects[($Objects.Count / 2) - 1] | Select -ExpandProperty Counter
        }
        else{
            Write-Verbose "[PROCESS] Dataset is even numbered."
            $Q2Value1 = $Objects[($Objects.Count / 2)] | Select -ExpandProperty Counter
            $Q2Value2 = $Objects[($Objects.Count / 2) - 1] | Select -ExpandProperty Counter
            $Q2 = ($Q2Value1 + $Q2Value2) / 2
        }
        Write-Verbose "[PROCESS] Q2 = $Q2"

        # Find the lower and upper median
        if ($Objects.Count % 2){
            # Get lower portion of data
            $LowerPortion = $Objects[0 .. (($Objects.Count / 2) - 1)]

            # Find median of lower portion
            if ($LowerPortion.Count % 2){
                $Q1 = $LowerPortion[($LowerPortion.Count / 2) - 1] | Select -ExpandProperty Counter
            }
            else {
                $Q1Value1 = $LowerPortion[($LowerPortion.Count / 2)] | Select -ExpandProperty Counter
                $Q1Value2 = $LowerPortion[($LowerPortion.Count / 2) -1] | Select -ExpandProperty Counter
                $Q1 = ($Q1Value1 + $Q1Value2) / 2
            }
            Write-Verbose "[PROCESS] Q1 = $Q1"

            # Get upper portion of data
            $LastItem = $Objects.Count
            $UpperPortion = $Objects[($Objects.Count / 2) .. $LastItem]

            # Find median of upper portion
            if ($UpperPortion.Count % 2){
                $Q3 = $UpperPortion[($UpperPortion.Count / 2) - 1] | Select -ExpandProperty Counter
            }
            else {
                $Q3Value1 = $UpperPortion[($UpperPortion.Count / 2)] | Select -ExpandProperty Counter
                $Q3Value2 = $UpperPortion[(($UpperPortion.Count / 2) - 1)] | Select -ExpandProperty Counter
                $Q3 = ($Q3Value1 + $Q3Value2) / 2
            }
            Write-Verbose "[PROCESS] Q3 = $Q3"
        }

        else {
            # Get lower portion of data
            $LowerPortion = $Objects[0 .. (($Objects.Count / 2) - 1)]

            # Find median of lower portion
            if ($LowerPortion.Count % 2){
                $Q1 = $LowerPortion[($LowerPortion.Count / 2) - 1] | Select -ExpandProperty Counter
            }
            else{
                $Q1Value1 = $LowerPortion[($LowerPortion.Count / 2)] | Select -ExpandProperty Counter
                $Q1Value2 = $LowerPortion[(($LowerPortion.Count / 2) - 1)] | Select -ExpandProperty Counter
                $Q1 = ($Q1Value1 + $Q1Value2) / 2
            }
            Write-Verbose "[PROCESS] Q1 = $Q1"

            # Get upper portion of data
            $LastItem = $Objects.Count
            $UpperPortion = $Objects[($Objects.Count / 2) .. $LastItem]

            # Find median of upper portion
            if ($UpperPortion.Count % 2){
                $Q3 = $UpperPortion[($UpperPortion.Count / 2) - 1] | Select -ExpandProperty Counter
            }
            else {
                $Q3Value1 = $UpperPortion[($UpperPortion.Count / 2)] | Select -ExpandProperty Counter
                $Q3Value2 = $UpperPortion[(($UpperPortion.Count / 2) - 1)] | Select -ExpandProperty Counter
                $Q3 = ($Q3Value1 + $Q3Value2) / 2
            }
            Write-Verbose "[PROCESS] Q3 = $Q3"
        }

        # Calculate the difference
        $IQR = $Q3 - $Q1
        Write-Verbose "[PROCESS] IQR = $IQR"

        # Find the outliers
        foreach ($Object in $Objects){
            $Counter = $Object | Select -ExpandProperty Counter
            if ($Counter -gt 0 -and $Counter -lt $IQR ){
                Write-Verbose "[PROCESS] $($Object.Department) is an outlier."
                $Object.Flagged = 1
            }
        }
    }

    End{
        Write-Verbose "[END    ] Outputting flagged custom objects."
        Write-Output $Objects | Where-Object {$_.Flagged -eq 1}
    }
}
