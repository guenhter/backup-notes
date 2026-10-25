param(
    [string]$TaskName = "UserHomeBackup",
    [string]$Source = "$env:USERPROFILE",
    [string]$Destination = "Z:\",
    [string]$BatchFilePath = "$env:USERPROFILE\.backup\BackupJob.ffs_batch"
)

$ErrorActionPreference = 'Stop'

$homeDir = [Environment]::GetFolderPath('UserProfile')
$backupDir = Join-Path $homeDir '.backup'
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

if (Test-Path $backupDir) {
    [System.IO.File]::SetAttributes($backupDir, [System.IO.FileAttributes]::Hidden)
}

$BatchFilePath = [System.IO.Path]::GetFullPath($BatchFilePath)
if (-not (Test-Path (Split-Path $BatchFilePath -Parent))) {
    New-Item -ItemType Directory -Path (Split-Path $BatchFilePath -Parent) -Force | Out-Null
}

$sourceDir = (Resolve-Path $Source).Path
$destinationDir = $Destination.TrimEnd('\\')

$xml = @'
<?xml version="1.0" encoding="utf-8"?>
<FreeFileSync XmlType="BATCH" XmlFormat="23">
    <Notes/>
    <Compare>
        <Variant>TimeAndSize</Variant>
        <Symlinks>Exclude</Symlinks>
        <IgnoreTimeShift/>
    </Compare>
    <Synchronize>
        <Differences LeftOnly="right" LeftNewer="right" RightNewer="right" RightOnly="right"/>
        <DeletionPolicy>Permanent</DeletionPolicy>
        <VersioningFolder Style="Replace"/>
    </Synchronize>
    <Filter>
        <Include>
            <Item>*</Item>
        </Include>
        <Exclude>
            <Item>\System Volume Information\</Item>
            <Item>\$Recycle.Bin\</Item>
            <Item>\RECYCLE?\</Item>
            <Item>\Recovery\</Item>
            <Item>*\thumbs.db</Item>
            <Item>\Downloads\</Item>
            <Item>\OneDrive\</Item>
            <Item>\AppData\</Item>
            <Item>\NTUSER.DAT*</Item>
            <Item>\ntuser.ini</Item>
            <Item>\IntelGraphicsProfiles\</Item>
            <Item>\.copilot\</Item>
            <Item>\.vscode\</Item>
            <Item>\.vscode-shared\</Item>
        </Exclude>
        <SizeMin Unit="None">0</SizeMin>
        <SizeMax Unit="None">0</SizeMax>
        <TimeSpan Type="None">0</TimeSpan>
    </Filter>
    <FolderPairs>
        <Pair>
            <Left>%UserProfile%</Left>
            <Right>Z:\</Right>
        </Pair>
    </FolderPairs>
    <Errors Ignore="false" Retry="0" Delay="5"/>
    <PostSyncCommand Condition="Completion"/>
    <LogFolder/>
    <EmailNotification Condition="Always"/>
    <GridViewType>Action</GridViewType>
    <Batch>
        <ProgressDialog Minimized="true" AutoClose="true"/>
        <ErrorDialog>Show</ErrorDialog>
        <PostSyncAction>None</PostSyncAction>
    </Batch>
</FreeFileSync>
'@

Set-Content -Path $BatchFilePath -Value $xml -Encoding UTF8

$existingTask = Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object {
        $_.TaskName -eq $TaskName -and ($_.TaskPath -eq '\' -or $_.TaskPath -eq '')
    }

if ($existingTask) {
    Unregister-ScheduledTask -TaskName $TaskName -TaskPath '\' -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute $BatchFilePath
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date -RepetitionInterval (New-TimeSpan -Hours 1)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden

$task = New-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -Description "Scheduled file synchronization using FreeFileSync"
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null

Write-Host "Backup task recreated."
Write-Host "Batch file: $BatchFilePath"
Write-Host "Source: $sourceDir"
Write-Host "Destination: $destinationDir"
