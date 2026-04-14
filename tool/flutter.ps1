# Wrapper for `flutter` on Windows.
# Flutter's native_assets step copies sqlite3.dll into build\ on every
# `test`/`run`/`build`. If a prior dart.exe or flutter_tester.exe survived
# (crash, Ctrl-C timing, hot-restart), it keeps the DLL locked and the next
# invocation fails with "Cannot create a file when that file already exists"
# (errno 183). This wrapper kills stale host processes and removes the
# locked DLL before handing off to flutter.

$ErrorActionPreference = 'SilentlyContinue'

Get-Process flutter_tester, dart, dartaotruntime, dartvm | Stop-Process -Force

$dll = Join-Path $PSScriptRoot '..\build\native_assets\windows\sqlite3.dll'
if (Test-Path $dll) { Remove-Item $dll -Force }

& 'C:\Flutter\flutter\bin\flutter.bat' @args
exit $LASTEXITCODE
