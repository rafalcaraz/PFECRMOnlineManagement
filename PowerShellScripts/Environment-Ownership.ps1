$allEnvironments = Get-AdminPowerAppEnvironment -Capacity
$allEnvironments_filtered = $allEnvironments | Where-Object { $_.Internal.properties.environmentSku -ne "NotSpecified" } # Teams
$allEnvironments_filtered = $allEnvironments_filtered | Where-Object { $_.Internal.properties.environmentSku -ne "Developer" } # Developer
$allEnvironments_filtered = $allEnvironments_filtered | Where-Object { $_.Internal.properties.maxAllowedExpirationTime -eq $null } # Trial

$capacityTotals = [PSCustomObject]@{
    databaseConsumed =  ((($allEnvironments_filtered.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Database"}).actualConsumption) | Measure-Object -Sum).Sum
    fileConsumed =  ((($allEnvironments_filtered.Capacity | Where-Object -FilterScript {$_.capacityType -eq "File"}).actualConsumption) | Measure-Object -Sum).Sum
    logConsumed =  ((($allEnvironments_filtered.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Log"}).actualConsumption) | Measure-Object -Sum).Sum
    finOpsDatabaseConsumed =  ((($allEnvironments_filtered.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsDatabase"}).actualConsumption) | Measure-Object -Sum).Sum
    finOpsFileConsumed =  ((($allEnvironments_filtered.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsFile"}).actualConsumption) | Measure-Object -Sum).Sum
}

$allMakers_detailed = $allEnvironments_filtered.CreatedBy | Sort-Object userPrincipalName -Unique

$generalInfo = @()
foreach($maker in $allMakers_detailed){
    $makerEmail = $maker.userPrincipalName
    $makerName = $maker.displayName
    $makerEnvironments = $allEnvironments_filtered | Where-Object { $_.CreatedBy.userPrincipalName -eq $makerEmail }
    $makerEnvironmentCount = $makerEnvironments.Count
    $makerEnvironmentNames = $makerEnvironments | Select-Object -ExpandProperty displayName
    # Write-Host "Maker: $makerName ($makerEmail) has $makerEnvironmentCount environment(s): $makerEnvironmentNames"

    $generalInfo += [PSCustomObject]@{
        MakerName = $makerName
        MakerEmail = $makerEmail
        EnvironmentCount = $makerEnvironmentCount
        EnvironmentNames = $makerEnvironmentNames #-join ", "
        Environments = $makerEnvironments
        CapacityConsumption = [PSCustomObject]@{
            dbConsumed = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Database"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
            fileConsumed = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "File"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
            logConsumed = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Log"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
            finOpsDbConsumed = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsDatabase"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
            finOpsFileConsumed = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsFile"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        }
        Database = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Database"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        File = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "File"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        Log = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Log"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        FinOpsDB = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsDatabase"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        FinOpsFile = ($makerEnvironments.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsFile"}).actualConsumption | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    }
}

$generalInfo = $generalInfo | Sort-Object "EnvironmentCount" -Descending
$generalInfo | Select-Object MakerName, MakerEmail,EnvironmentCount,Database,File,Log,FinOpsDB,FinOpsFile | Format-Table -AutoSize

########## Below Is to get the info for a specific user ##########

$userEmail = ""
$userEnvs = ($generalInfo | Where-Object -FilterScript {$_.MakerEmail -eq $userEmail} | Select-Object Environments)
# $userEnvs.Environments.DisplayName

$userEnvInfo = @()
foreach($env in $userEnvs.Environments){

    $userEnvInfo += [PSCustomObject]@{
        DisplayName = $env.DisplayName
        DB = ($env.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Database"}).actualConsumption
        Log = ($env.Capacity | Where-Object -FilterScript {$_.capacityType -eq "Log"}).actualConsumption
        File = ($env.Capacity | Where-Object -FilterScript {$_.capacityType -eq "File"}).actualConsumption
        FinOpsDb = ($env.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsDatabase"}).actualConsumption
        FinOpsFile = ($env.Capacity | Where-Object -FilterScript {$_.capacityType -eq "FinOpsFile"}).actualConsumption
    }
}

$userEnvInfo | Format-Table -AutoSize