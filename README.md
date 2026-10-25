# backup-notes

1. Install https://github.com/hkneptune/FreeFileSync
2. Run the script in a elevated powershell terminal
    ```ps1
    $url = 'https://raw.githubusercontent.com/guenhter/backup-notes/main/Create-BackupTask.ps1'
    $p = Join-Path $env:TEMP 'Create-BackupTask.ps1'
    Invoke-WebRequest $url -OutFile $p
    powershell -ExecutionPolicy Bypass -File $p
    ```

