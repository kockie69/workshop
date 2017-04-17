# ---------------------  VARIABLES (app.config)  --------------------------------------------------------------------------------------------------------------------
$relativePathToCODEDirectory         = ".\.."        # Relative path from script to ECL code
$relativePathToImportsDirectory      = ".\.."        # Relative path from script to base path for ECL IMPORTS
$logfile                             = "EclSyntaxCheck.log"  # 
$ignoreWarnings                      = $true                 # $true will make syntax check to ignore warnings
$excludedDirectories                 = "DataPatterns", "ECL Syntax Check", "WIP" # Directories under $CODEDirectory to be ignored
$eclClientTools                      = "C:\Program Files (x86)\HPCCSystems\6.0.2\clienttools\bin" 