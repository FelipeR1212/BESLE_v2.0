[CmdletBinding()]
param(
    [string]$LauncherPath
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($LauncherPath)) {
    $LauncherPath = Join-Path $PSScriptRoot "../packaging/windows/run-besle.ps1.in"
}
$tokens = $null
$parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile(
    (Resolve-Path -LiteralPath $LauncherPath).Path, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) {
    throw "El lanzador contiene errores de sintaxis: $parseErrors"
}
$functionAst = $ast.Find({
    param($node)
    ($node -is [Management.Automation.Language.FunctionDefinitionAst]) -and
        ($node.Name -eq "Get-BesleMpiProcesses")
}, $true)
if ($null -eq $functionAst) {
    throw "Falta Get-BesleMpiProcesses en el lanzador."
}
# Load the actual production function without executing the launcher's menu.
. ([scriptblock]::Create($functionAst.Extent.Text))

$cases = @(
    @{ Name = "two"; Text = "&BESLE_CONFIG mpi_processes = 2 /"; Expected = 2 },
    @{ Name = "four"; Text = "&BESLE_CONFIG mpi_processes = 4 /"; Expected = 4 },
    @{ Name = "eight"; Text = "&BESLE_CONFIG mpi_processes = 8 /"; Expected = 8 },
    @{ Name = "legacy"; Text = "&BESLE_CONFIG time_steps = 1 /"; Expected = 2 },
    @{ Name = "uppercase"; Text = "&besle_config MPI_PROCESSES = +4 /"; Expected = 4 },
    @{ Name = "comma"; Text = "&BESLE_CONFIG mpi_processes = 4, time_steps = 1 /"; Expected = 4 },
    @{ Name = "multiline"; Text = "&BESLE_CONFIG`r`n mpi_processes =`r`n8`r`n/"; Expected = 8 },
    @{ Name = "end"; Text = "&BESLE_CONFIG mpi_processes = 4 &END"; Expected = 4 },
    @{ Name = "comment"; Text = "! mpi_processes = 99`n&BESLE_CONFIG mpi_processes = 4 ! ignored`n/"; Expected = 4 },
    @{ Name = "comment-only"; Text = "&BESLE_CONFIG`n! mpi_processes = 99`n/"; Expected = 2 },
    @{ Name = "quoted"; Text = "&BESLE_CONFIG mesh_file = 'mpi_processes = 99 /', mpi_processes = 4 /"; Expected = 4 },
    @{ Name = "escaped-quote"; Text = "&BESLE_CONFIG mesh_file = 'dir''mpi_processes = 99 /', mpi_processes = 4 /"; Expected = 4 },
    @{ Name = "double-quoted"; Text = '&BESLE_CONFIG mesh_file = "mpi_processes = 99 /", mpi_processes = 4 /'; Expected = 4 },
    @{ Name = "other-group"; Text = "&OTHER mpi_processes = 99 /`n&BESLE_CONFIG mpi_processes = 4 /`nmpi_processes = 88"; Expected = 4 },
    @{ Name = "zero"; Text = "&BESLE_CONFIG mpi_processes = 0 /"; Expected = -1 },
    @{ Name = "one"; Text = "&BESLE_CONFIG mpi_processes = 1 /"; Expected = -1 },
    @{ Name = "negative"; Text = "&BESLE_CONFIG mpi_processes = -4 /"; Expected = -1 },
    @{ Name = "fraction"; Text = "&BESLE_CONFIG mpi_processes = 4.5 /"; Expected = -1 },
    @{ Name = "text"; Text = "&BESLE_CONFIG mpi_processes = four /"; Expected = -1 },
    @{ Name = "quoted-number"; Text = "&BESLE_CONFIG mpi_processes = '4' /"; Expected = -1 },
    @{ Name = "empty"; Text = "&BESLE_CONFIG mpi_processes = , /"; Expected = -1 },
    @{ Name = "overflow"; Text = "&BESLE_CONFIG mpi_processes = 2147483648 /"; Expected = -1 },
    @{ Name = "duplicate"; Text = "&BESLE_CONFIG mpi_processes = 2, mpi_processes = 4 /"; Expected = -1 },
    @{ Name = "missing-end"; Text = "&BESLE_CONFIG mpi_processes = 4"; Expected = -1 },
    @{ Name = "missing-group"; Text = "! &BESLE_CONFIG mpi_processes = 4 /"; Expected = -1 }
)

$caseRoot = Join-Path ([IO.Path]::GetTempPath()) ("besle-mpi-tests-" + [guid]::NewGuid().ToString("N"))
[void](New-Item -ItemType Directory -Path $caseRoot)
foreach ($case in $cases) {
    $configPath = Join-Path $caseRoot ($case.Name + ".nml")
    Set-Content -LiteralPath $configPath -Value $case.Text -Encoding ascii
    $result = $null
    $caught = $null
    try {
        $result = Get-BesleMpiProcesses -ConfigurationPath $configPath
    }
    catch {
        $caught = $_
    }
    if ($case.Expected -eq -1) {
        if ($null -eq $caught) {
            throw "La configuracion invalida '$($case.Name)' fue aceptada: $result"
        }
    }
    elseif (($null -ne $caught) -or ($result -ne $case.Expected)) {
        throw "Fallo '$($case.Name)': esperado $($case.Expected), obtenido $result, error $caught"
    }
    Write-Host "OK: $($case.Name)"
}
Write-Host "$($cases.Count) pruebas del lector MPI aprobadas."
