<#
.SYNOPSIS
  Compiles src\host\launcher.cs and assembles a runnable MD Editor folder.

.DESCRIPTION
  Wraps the csc command documented in the header of launcher.cs. Output goes to -OutDir
  (default: dist\) and contains md-editor.exe plus the files it needs next to it:
  md-editor.html, the WebView2 DLLs and, if supplied, the icon files.

  NOTE: written from the documented compile command; not yet run against the real
  WebView2 SDK DLLs.

.PARAMETER LibDir
  Folder containing Microsoft.Web.WebView2.Core.dll, Microsoft.Web.WebView2.WinForms.dll
  and WebView2Loader.dll (x64), e.g. extracted from the Microsoft.Web.WebView2 NuGet package.

.PARAMETER IconPath
  Optional md-editor.ico, embedded as the exe icon and copied next to the exe.

.PARAMETER HeaderIconPath
  Optional md-editor-icon.png (title-bar logo), copied next to the exe.

.EXAMPLE
  .\scripts\build-host.ps1 -LibDir .\lib
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $LibDir,
    [string] $IconPath,
    [string] $HeaderIconPath,
    [string] $OutDir = (Join-Path $PSScriptRoot '..\dist')
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$source   = Join-Path $repoRoot 'src\host\launcher.cs'
$page     = Join-Path $repoRoot 'src\web\md-editor.html'
$csc      = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'

if (-not (Test-Path $csc))    { throw "C# compiler not found: $csc" }
if (-not (Test-Path $source)) { throw "Missing $source" }
if (-not (Test-Path $page))   { throw "Missing $page" }
if (-not (Test-Path $LibDir)) { throw "LibDir not found: $LibDir" }

$LibDir = (Resolve-Path $LibDir).Path
$requiredDlls = @(
    'Microsoft.Web.WebView2.Core.dll',
    'Microsoft.Web.WebView2.WinForms.dll',
    'WebView2Loader.dll'
)
foreach ($dll in $requiredDlls) {
    if (-not (Test-Path (Join-Path $LibDir $dll))) { throw "Missing $dll in $LibDir" }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
$exe    = Join-Path $OutDir 'md-editor.exe'

$cscArgs = @(
    '-nologo', '-target:winexe', '-platform:x64',
    "-out:$exe",
    "-reference:$(Join-Path $LibDir 'Microsoft.Web.WebView2.Core.dll')",
    "-reference:$(Join-Path $LibDir 'Microsoft.Web.WebView2.WinForms.dll')"
)
if ($IconPath) {
    if (-not (Test-Path $IconPath)) { throw "IconPath not found: $IconPath" }
    $cscArgs += "-win32icon:$((Resolve-Path $IconPath).Path)"
}
$cscArgs += $source

Write-Host "Compiling launcher.cs -> $exe"
& $csc @cscArgs
if ($LASTEXITCODE -ne 0) { throw "csc failed with exit code $LASTEXITCODE" }

# Everything the exe loads from its own folder.
Copy-Item $page -Destination $OutDir -Force
foreach ($dll in $requiredDlls) { Copy-Item (Join-Path $LibDir $dll) -Destination $OutDir -Force }
if ($IconPath)       { Copy-Item $IconPath       -Destination (Join-Path $OutDir 'md-editor.ico')      -Force }
if ($HeaderIconPath) {
    if (-not (Test-Path $HeaderIconPath)) { throw "HeaderIconPath not found: $HeaderIconPath" }
    Copy-Item $HeaderIconPath -Destination (Join-Path $OutDir 'md-editor-icon.png') -Force
}

Write-Host "Done. Run: $exe"
