if (-not (Get-Module -Name PSReadLine -ListAvailable))
{
    Write-Host "PSReadLine module not found. Attempting to install via PowerShellGet..."
    try
    {
        Install-Module -Name PSReadLine -AllowClobber -Force
        Write-Host "PSReadLine installed successfully. Importing..."
        Import-Module PSReadLine
    } catch
    {
        Write-Error "Failed to install PSReadLine. Error: $_"
    }
} else
{
    Import-Module PSReadLine
}

if (-not (Get-Module -ListAvailable -Name Terminal-Icons))
{
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module -Name Terminal-Icons

function Start-PythonWithMath
{
    python -c "from math import *; print('Math library imported.'); import code; code.interact(local=locals())"
}
function Open-In-Nvim
{
    param(
        [string]$path
    )
    Set-Location $path
    nvim .
}
function Touch
{
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Path
    )

    process
    {
        foreach ($file in $Path)
        {
            if (Test-Path -Path $file)
            {
                # Update the access and modification times
                $currentDateTime = Get-Date
                (Get-Item $file).LastWriteTime = $currentDateTime
                (Get-Item $file).LastAccessTime = $currentDateTime
            } else
            {
                # Create the file if it doesn't exist
                New-Item -ItemType File -Path $file
            }
        }
    }
}
function e
{
    param(
        [string]$path = "."
    )
    explorer $path
}

function Get-PubIP
{
    (Invoke-WebRequest http://ifconfig.me/ip).Content
}

function uptime
{
    $uptime = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime | ForEach-Object { [Management.ManagementDateTimeConverter]::ToDateTime($_) }
    $uptime = New-TimeSpan -Start $uptime -End (Get-Date) | Select-Object -Property Days, Hours, Minutes, Seconds
    "$( $uptime.Days ) days, $( $uptime.Hours ) hours, $( $uptime.Minutes ) minutes, $( $uptime.Seconds ) seconds"
}

function sha256
{
    param(
        [string]$path = ""
    )
    if (-not (Test-Path $path))
    {
        Write-Host "File not found" -ForegroundColor Red
        return
    }
    $hash = Get-FileHash $path -Algorithm SHA256
    Write-Host $hash.Hash
}



function df
{
    $drives = Get-PSDrive -PSProvider FileSystem
    foreach ($drive in $drives)
    {
        [PSCustomObject]@{
            Drive = $drive.Name
            "Total Size" = [math]::round($drive.Used/1GB + $drive.Free/1GB, 2) + " GB"
            "Used" = [math]::round($drive.Used/1GB, 2) + " GB"
            "Available" = [math]::round($drive.Free/1GB, 2) + " GB"
            "Used (%)" = [math]::round(($drive.Used/($drive.Used + $drive.Free))*100, 2) + " %"
        }
    }
}


function unzip()
{
    param (
        [string] $file = $( throw "Please provide a file to unzip" ),
        [string] $dest = "."
    )

    Expand-Archive -Path $file -DestinationPath $dest
}

function zip()
{
    param (
        [string] $file = $( throw "Please provide a file to zip" ),
        [string] $dest = "."
    )

    Compress-Archive -Path $file -DestinationPath $dest
}

function which($name)
{
    Get-Command $name | Select-Object -ExpandProperty Path
}

function head
{
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function ps
{
    Get-Process | Select-Object -Property Id, ProcessName, CPU, WS, VM
}

function tail
{
    param($Path, $n = 10)
    Get-Content $Path -Tail $n
}

function la
{
    Get-ChildItem -Path . -Force | Format-Table -AutoSize
}
function ll
{
    Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize
}

function mkcd($name)
{
    mkdir $name
    Set-Location $name
}

function rmrf($path)
{
    $confirm = Read-Host "Are you sure you want to delete $path? (y/n)"
    if ($confirm -eq "y")
    {
        Remove-Item $path -Recurse -Force
    }
}
function chown
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$User,
        [Parameter(Mandatory = $true)]
        [string[]]$Path
    )
    foreach ($file in $Path)
    {
        icacls $file /setowner $User
    }
}
function du
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    Get-ChildItem -Path $Path -Recurse | Measure-Object -Property Length -Sum | Select-Object @{Name="Size (MB)";Expression={[math]::round($_.Sum / 1MB, 2)}}
}

function grep
{
    param(
        [string]$Pattern,
        [string]$Path
    )
    Select-String -Pattern $Pattern -Path $Path
}

function wget
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [string]$Output = (Split-Path -Leaf $Url)
    )
    Invoke-WebRequest -Uri $Url -OutFile $Output
}

function curl
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [string]$Body
    )
    Invoke-RestMethod -Uri $Url -Method $Method -Headers $Headers -Body $Body
}

function ps1conf
{
    nvim $PROFILE
}

function kill
{
    param(
        [Parameter(Mandatory = $true)]
        [int]$Pid
    )
    Stop-Process -Id $Pid -Force
}

function find
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Name = "*"
    )
    Get-ChildItem -Path $Path -Recurse -Filter $Name
}

function locate
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        [string]$Path = "C:\"
    )
    Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue -Filter $Pattern
}


function top
{
    while ($true)
    {
        Clear-Host
        Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 -Property Id, ProcessName, CPU, WS, VM
        Start-Sleep -Seconds 1
    }
}

function man
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    Get-Help $Command -Full
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView


New-Alias -Name pwsh -Value powershell
New-Alias -Name cdn -Value Open-In-Nvim
New-Alias -Name vim -Value nvim
New-Alias -Name calc -Value Start-PythonWithMath