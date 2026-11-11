# Installs every skill under skills/ and every extension under extensions/ into omp's agent dir.
# From a clone:   powershell -ExecutionPolicy Bypass -File install.ps1
# Without a clone: irm https://raw.githubusercontent.com/ataberkus/omp-skills/main/install.ps1 | iex
# Target: $env:OMP_AGENT_DIR, default ~\.omp\agent. Existing files with the same name are replaced.
$ErrorActionPreference = 'Stop'
$agentDir = if ($env:OMP_AGENT_DIR) { $env:OMP_AGENT_DIR } else { Join-Path $HOME '.omp\agent' }

$src = $PSScriptRoot
$tmp = $null
if (-not $src -or -not (Test-Path (Join-Path $src 'skills'))) {
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("omp-skills-" + [guid]::NewGuid())
  New-Item -ItemType Directory -Path $tmp | Out-Null
  $zip = Join-Path $tmp 'repo.zip'
  Invoke-WebRequest -UseBasicParsing 'https://github.com/ataberkus/omp-skills/archive/refs/heads/main.zip' -OutFile $zip
  Expand-Archive $zip -DestinationPath $tmp
  $src = (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName
}

try {
  $skills = Join-Path $agentDir 'skills'
  $extensions = Join-Path $agentDir 'extensions'
  New-Item -ItemType Directory -Force -Path $skills, $extensions | Out-Null
  foreach ($skill in Get-ChildItem (Join-Path $src 'skills') -Directory) {
    $dest = Join-Path $skills $skill.Name
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
    Copy-Item -Recurse $skill.FullName $dest
    Write-Host "skill      $dest"
  }
  foreach ($ext in Get-ChildItem (Join-Path $src 'extensions') -File) {
    Copy-Item -Force $ext.FullName (Join-Path $extensions $ext.Name)
    Write-Host "extension  $(Join-Path $extensions $ext.Name)"
  }
  Write-Host "`nDone. Restart omp (or open a new session) to load new extensions."
} finally {
  if ($tmp) { Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue }
}
