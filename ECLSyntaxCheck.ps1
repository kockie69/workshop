# Script author      	: Oscar Foley
# Script location    	: $odin/Build/BuildDefinition
# Script Description 	: This script makes a syntax check of all ecl code
# Version				: 1.0
# Notes

function Write-LogMessage($message, $logfile, $colour = "") {
    if ($colour.Equals("Red")) {
        Write-Host $message -ForegroundColor Red
    }
    elseif ($colour.Equals("Green")) {
        Write-Host $message -ForegroundColor Green
    }
    else {
        Write-Host $message
    }
    Add-Content $logfile $message
}

function DetectPowershellVersion($minVersion = 3, $logFile) {
    # Check Powershell version
    $PSVersion = $PSVersionTable.PSVersion
    Write-LogMessage "Detected PowerShell version: $PSVersion" $logFile
    if ( ([int]$PSVersion.Major) -lt $minVersion) {
        throw "ERROR. Script needs Powershell $minVersion or higher."
    }
    
}

function DetectECLCCVersion($logFile) {
    $cmdName = "$eclClientTools\eclcc.exe"
    if (Get-Command $cmdName -errorAction SilentlyContinue) {
        Write-LogMessage "$cmdName exists" $logFile
    }
    else {
        throw "Cannot find eclcc $cmdName. Please install correct version from https://hpccsystems.com/download/developer-tools/client-tools"
    }

    if (!(Get-Command "eclcc" -errorAction SilentlyContinue)) {
        $env:Path += ";$eclClientTools"
    }

    
}

function PrintCompilingErrors($fileName, $stringList, $ignoreWarnings = $false, $logfile) {
    foreach ($element in $stringlist) {
        if ($element.StartsWith($fileName)) {
            if ($ignoreWarnings) {
                if (!$element.Contains(': warning C')) {   
                    Write-LogMessage " $element" $logfile
                }
            }
            else {
                Write-LogMessage " $element" $logfile
            }
        }
        
    }

}

function SyntaxCheckAllFilesInDirectory($BASEDirectory, $BASEImportsDirectory, $ignoreWarnings, $logfile) {
    $list = Get-ChildItem -Path $BASEDirectory -Recurse -Filter "*.ecl"
    foreach ($item in $list) {
        #if(!$item.DirectoryName.Equals("C:\Projects\Stash\PeopleAnalytics\Incoming\SalarySurveys\Individuals"))
        #{
        $fullName = "$($item.DirectoryName)\$($item.Name)"
        $directory = $($item.DirectoryName)
        $cmdOuput = cmd /c eclcc -syntax -I="$BASEImportsDirectory" $fullName '2>&1' 
            
        if ($cmdOuput -and $cmdOuput -Match ': error C') {
            $global:hasErrors = $TRUE;
        }
        PrintCompilingErrors $fullName $cmdOuput $ignoreWarnings $logfile 
        #}
    }
}

# Imports
$scriptsDirectory = Split-Path $MyInvocation.MyCommand.Definition -parent
. $(Join-Path $scriptsDirectory "ECLSyntaxCheck.config.ps1") # Load app.config
cd $scriptsDirectory
$hasErrors
# MAIN
try {
    cls
    Remove-Item -Force "$scriptsDirectory\$logFile" -ErrorAction SilentlyContinue
    Write-LogMessage "Initializing log file: $scriptsDirectory\$logFile" $logFile
    
    DetectPowershellVersion 3 $logfile
    Write-LogMessage "Configuration (from ECLSyntaxCheck.config.ps1)" $logfile
    Write-LogMessage "- Relative Path to code directory    : $relativePathToCODEDirectory" $logfile
    Write-LogMessage "- Relative Path to imports directory : $relativePathToImportsDirectory" $logfile
    Write-LogMessage "- Log file name                      : $logfile" $logfile
    Write-LogMessage "- Ignore Warnings                    : $ignoreWarnings" $logfile
    Write-LogMessage "- Exclude Directories                : $excludedDirectories" $logfile
    Write-LogMessage "- HPCC Client Tools path             : $eclClientTools" $logfile
    Write-LogMessage "Starting ECL SyntaxCheck..." $logfile

    DetectECLCCVersion $logfile
    $CODEDirectory = (Get-Item -Path $relativePathToCODEDirectory -Verbose).FullName + '\'
    $ImportsDirectory = (Get-Item -Path $relativePathToImportsDirectory -Verbose).FullName
    Write-LogMessage "Absolute Path to code directory    : $CODEDirectory" $logfile
    Write-LogMessage "Absolute Path to imports directory : $ImportsDirectory" $logfile
    
    Write-LogMessage "Starting ECL Syntax check in all *.ecl files in $CODEDirectory" $logfile
    
    Write-LogMessage "Checking directories from $CODEDirectory" $logfile
    $list = Get-ChildItem -Path $CODEDirectory -Directory
    $global:hasErrors = $FALSE
    foreach ($dir in $list) {
        if ($excludedDirectories.Contains($dir.Name)) {
            Write-LogMessage " -- excluded - $($dir.FullName)" $logfile
        }
        else {
            Write-LogMessage " $($dir.FullName)" $logfile
            SyntaxCheckAllFilesInDirectory $dir.FullName $ImportsDirectory $ignoreWarnings $logfile
        }
    
    }
    
    Write-LogMessage "Finished ECL SyntaxCheck :-)" $logfile
   
    if (!$global:hasErrors) {
        Write-LogMessage "
                                                                                                                                   
                                                                                                                                   
   SSSSSSSSSSSSSSS                                                                                                                 
 SS:::::::::::::::S                                                                                                                
S:::::SSSSSS::::::S                                                                                                                
S:::::S     SSSSSSS                                                                                                                
S:::::S            uuuuuu    uuuuuu      cccccccccccccccc    cccccccccccccccc    eeeeeeeeeeee        ssssssssss       ssssssssss   
S:::::S            u::::u    u::::u    cc:::::::::::::::c  cc:::::::::::::::c  ee::::::::::::ee    ss::::::::::s    ss::::::::::s  
 S::::SSSS         u::::u    u::::u   c:::::::::::::::::c c:::::::::::::::::c e::::::eeeee:::::eess:::::::::::::s ss:::::::::::::s 
  SS::::::SSSSS    u::::u    u::::u  c:::::::cccccc:::::cc:::::::cccccc:::::ce::::::e     e:::::es::::::ssss:::::ss::::::ssss:::::s
    SSS::::::::SS  u::::u    u::::u  c::::::c     cccccccc::::::c     ccccccce:::::::eeeee::::::e s:::::s  ssssss  s:::::s  ssssss 
       SSSSSS::::S u::::u    u::::u  c:::::c             c:::::c             e:::::::::::::::::e    s::::::s         s::::::s      
            S:::::Su::::u    u::::u  c:::::c             c:::::c             e::::::eeeeeeeeeee        s::::::s         s::::::s   
            S:::::Su:::::uuuu:::::u  c::::::c     cccccccc::::::c     ccccccce:::::::e           ssssss   s:::::s ssssss   s:::::s 
SSSSSSS     S:::::Su:::::::::::::::uuc:::::::cccccc:::::cc:::::::cccccc:::::ce::::::::e          s:::::ssss::::::ss:::::ssss::::::s
S::::::SSSSSS:::::S u:::::::::::::::u c:::::::::::::::::c c:::::::::::::::::c e::::::::eeeeeeee  s::::::::::::::s s::::::::::::::s 
S:::::::::::::::SS   uu::::::::uu:::u  cc:::::::::::::::c  cc:::::::::::::::c  ee:::::::::::::e   s:::::::::::ss   s:::::::::::ss  
 SSSSSSSSSSSSSSS       uuuuuuuu  uuuu    cccccccccccccccc    cccccccccccccccc    earchiewashere    sssssssssss      sssssssssss    
                                                                                                                                    
    " $logfile "Green"
    } 
    else {
        Write-LogMessage "
 .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
| |  _________   | || |  _______     | || |  _______     | || |     ____     | || |  _______     | |
| | |_   ___  |  | || | |_   __ \    | || | |_   __ \    | || |   .'    ``.   | || | |_   __ \    | |
| |   | |_  \_|  | || |   | |__) |   | || |   | |__) |   | || |  /  .--.  \  | || |   | |__) |   | |
| |   |  _|  _   | || |   |  __ /    | || |   |  __ /    | || |  | |    | |  | || |   |  __ /    | |
| |  _| |___/ |  | || |  _| |  \ \_  | || |  _| |  \ \_  | || |  \  ``--'  /  | || |  _| |  \ \_  | |
| | |_________|  | || | |____| |___| | || | |____| |___| | || |   ``.____.'   | || | |____| |___| | |
| |              | || |              | || |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

        " $logFile "Red"
    }
    $exitCode = 0 
}
Catch {
    $errorMessage = $_.Exception
    Write-LogMessage $errorMessage $logfile
    $exitCode = 1
}
finally {
    exit $exitCode
}