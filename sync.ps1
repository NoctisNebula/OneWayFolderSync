#declaring our arguments that will act as our constant variables
param (
    [string] $sourceFolder,
    [string] $replicaFolder,
    [string] $logFile,
    [int] $interval
)

#writing the starting output to the console
Write-Host "Welcome young padawan..."
Write-Host "We're starting folder synchronization..."
Write-Host "Source folder: $sourceFolder"
Write-Host "Replica folder: $replicaFolder"
Write-Host "Log file: $logFile"
Write-Host "Synchronization interval: $interval seconds"


#creating our streamwriter object that will output the logging to our declared $logFile
$logStream = [System.IO.StreamWriter]::new($logFile, $true)

#setting Autoflush to true so we won't have to manually flush the stream to be efficient and avoid data loss due to a potential crash
$logStream.AutoFlush = $true

#writing our first log entry to document the starting time 
#untill our program loop will start we are closing each log stream after writing to it to avoid data loss due to conflicts related to file usage

$logStream.WriteLine("$(Get-Date): - Sync started") 
$logStream.Close()


#checking if our source folder exists // if it doesn't we output an error and log it
if (-not (Test-Path $sourceFolder -PathType Container)) {
    Write-Host "Error: source folder $sourceFolder not found or not a folder"
	$logStream.WriteLine("Error: source folder $sourceFolder not found or not a folder!")
	$logStream.Close()
    Exit
}

#checking if our replica folder exists // if it doesn't we create it and we output & log the action
if (-not (Test-Path $replicaFolder -PathType Container)) {
    Write-Host "Replica folder $replicaFolder not found, creating..."
    New-Item $replicaFolder -ItemType Directory | Out-Null
	$logStream.Writeline("Replica folder $replicaFolder was not found, we just created it")
	$logStream.Close()
}


#creating our main loop that will constantly sync the folders at the given $interval
while ($true) { 
    #declaring our log stream again since we're closing it at the end of the loop
    $logStream = [System.IO.StreamWriter]::new($logFile, $true)
    $logStream.AutoFlush = $true
    Write-Host "Synchronizing folders..."
    $logStream.WriteLine("$(Get-Date): Starting folder synchronization...")  
	

    # Reading the files in replica folder and deleting those that don't exist in source folder then outputting to the terminal & logging the results
    Get-ChildItem -Path $replicaFolder -Recurse -File | Where-Object {
        $sourceFile = Join-Path $sourceFolder $_.FullName.Substring($replicaFolder.Length)
        -not (Test-Path $sourceFile)
    } | ForEach-Object {
        $filename = $_.FullName
        Remove-Item $filename
        Write-Host "Deleted file $filename"
        $logStream.WriteLine("$(Get-Date): Deleted file $filename")  		
		
    }

# Reading the files from the source folder and copying to the replica folder if the case, or if the source file is newer, then outputting to the terminal & logging the results
Get-ChildItem -Path $sourceFolder -Recurse -File | ForEach-Object {
    $filename = $_.FullName
    $destFilename = Join-Path $replicaFolder $_.FullName.Substring($sourceFolder.Length)
    if (-not (Test-Path $destFilename)) {
        Copy-Item $filename $destFilename
        Write-Host "Copied file $filename to $destFilename"
        $logStream.WriteLine("$(Get-Date): Copied file $filename to $destFilename") 
    } else {
        $sourceFileLastWriteTime = (Get-Item $filename).LastWriteTime
        $destFileLastWriteTime = (Get-Item $destFilename).LastWriteTime
        if ($sourceFileLastWriteTime -gt $destFileLastWriteTime) {
            Copy-Item $filename $destFilename -Force
            Write-Host "Updated file $filename in $destFilename"
            $logStream.WriteLine("$(Get-Date): Updated file $filename in $destFilename") 
        }
    }
}

    
	#Outputting the end of the syncronization 
    Write-Host "Finished synchronization at $(Get-Date)."
    $logStream.Writeline("$(Get-Date): Finished synchronization.")
	$logStream.Close()

    # Waiting for the next synchronization cycle
    Start-Sleep -Seconds $interval
}
