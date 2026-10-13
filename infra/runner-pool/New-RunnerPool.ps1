<#
.SYNOPSIS
Creates the Azure VMs that run jsonschema-benchmark's scheduled benchmarks, then deallocates them.

.DESCRIPTION
Creates a resource group and Count identical Linux VMs of one size, each with cloud-init.yaml (Docker, the benchmark's
tools, and the GitHub Actions runner, unregistered). The VMs accept no inbound connections: the workflow drives them
through `az vm run-command`. When cloud-init has finished on every VM, they are deallocated, so they cost only their
disks until the workflow starts them.

Needs the Azure CLI, signed in (az login) to the subscription that will hold the pool. See README.md for the rest of
the setup (the workflow's Azure identity, the GitHub App, the repository variables).

.PARAMETER ResourceGroup
The resource group to create (or reuse) for the pool.

.PARAMETER Location
The Azure region.

.PARAMETER Count
How many VMs.

.PARAMETER Size
The VM size. Every VM in the pool has the same size, so the same CPU model; the workflow checks the model on every
job (the BENCHMARK_CPU_MODEL variable).

.PARAMETER NamePrefix
VM names are <NamePrefix>-1, <NamePrefix>-2, ...

.EXAMPLE
pwsh infra/runner-pool/New-RunnerPool.ps1 -ResourceGroup jsonschema-benchmark -Location uksouth
#>
[CmdletBinding()]
param(
    [string] $ResourceGroup = "jsonschema-benchmark",
    [string] $Location = "uksouth",
    [int] $Count = 2,
    [string] $Size = "Standard_D4as_v7",
    [string] $NamePrefix = "jsb-runner"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Az([string[]] $Arguments) {
    $output = & az @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        $output | Write-Host
        throw "az $($Arguments -join ' ') failed (exit $LASTEXITCODE)"
    }
    return $output
}

$cloudInit = Join-Path $PSScriptRoot "cloud-init.yaml"
Invoke-Az @("group", "create", "--name", $ResourceGroup, "--location", $Location, "--output", "none") | Out-Null

$names = @(1..$Count | ForEach-Object { "$NamePrefix-$_" })
foreach ($name in $names) {
    Write-Host "Creating $name ($Size)"
    # A public IP for outbound access (new virtual networks have no default outbound access), and no inbound rules.
    Invoke-Az @(
        "vm", "create",
        "--resource-group", $ResourceGroup,
        "--name", $name,
        "--image", "Ubuntu2404",
        "--size", $Size,
        "--os-disk-size-gb", "64",
        "--storage-sku", "StandardSSD_LRS",
        "--admin-username", "azureuser",
        "--generate-ssh-keys",
        "--public-ip-sku", "Standard",
        "--nsg-rule", "NONE",
        "--custom-data", $cloudInit,
        "--output", "none"
    ) | Out-Null
}

foreach ($name in $names) {
    Write-Host "Waiting for cloud-init on $name"
    $result = Invoke-Az @(
        "vm", "run-command", "invoke",
        "--resource-group", $ResourceGroup,
        "--name", $name,
        "--command-id", "RunShellScript",
        "--scripts", "cloud-init status --wait; lscpu | sed -n 's/^Model name:[[:space:]]*//p'; ls /opt/actions-runner/run.sh",
        "--query", "value[0].message",
        "--output", "tsv"
    )
    $result | Write-Host
}

foreach ($name in $names) {
    Write-Host "Deallocating $name"
    Invoke-Az @("vm", "deallocate", "--resource-group", $ResourceGroup, "--name", $name, "--no-wait") | Out-Null
}

Write-Host ""
Write-Host "Pool ready. Set the repository variables:"
Write-Host "  BENCHMARK_RESOURCE_GROUP = $ResourceGroup"
Write-Host "  BENCHMARK_POOL           = $($names -join ',')"
Write-Host "  BENCHMARK_CPU_MODEL      = (the model name printed above)"
