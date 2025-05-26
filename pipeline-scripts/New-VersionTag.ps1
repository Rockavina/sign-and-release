<#
.SYNOPSIS
    Generates new version tag for git. 
.DESCRIPTION
    Generates new version tag for git.
    
    The version tag is based on the current date and the latest tag in the repository.
    
    The version tag is formatted as follows:
        vYYYY.0M.BUILD
    Where:
        YYYY  = Year
        0M    = Month (01-12)
        BUILD = Incremental build number (001, 002, etc.)

    Example:
        v2025.04.123
.NOTES
    Use in GitHub pipeline for version tags.
    Needs checkout action to use "fetch-depth: 0"
 .OUTPUTS
    version [string]
#>
[CmdletBinding()]
param()

# function to ensure unique tag
function GetUniqueTag {
    param (
        [ValidatePattern('^v([0-9]{4})\.([0-9]{2})\.([0-9]{3})$')]
        $Tag
    )
    
    # Check if tag exists
    if (git tag --list $Tag) {
        
        $null = $Tag -match '^v([0-9]{4})\.([0-9]{2})\.([0-9]{3})$'
        
        # Increment build by 1
        $NewTag = "v" + $matches[1] + "." + $matches[2] + "." + ('{0:d3}' -f ([int]$matches[3] + 1))
        
        GetUniqueTag -Tag $NewTag

    } else {
    
        return $Tag 
    
    }
}

# Verify current folder is a git repo
if (-not (git rev-parse --is-inside-work-tree)) {

    throw "Not a git repository. Aborting."
    
}

# Get info for tag
$Year       = Get-Date -Format "yyyy"
$Month      = Get-Date -Format "MM"
$DefaultTag = GetUniqueTag ("v" + $Year + "." + $Month + ".001")

# Get latest ref/tags
$GitLatestRevTag = git rev-list --tags --max-count=1

if ([string]::IsNullOrEmpty($GitLatestRevTag)) {

    $NewTag = $DefaultTag
    Write-Verbose "No existing tags, setting default: $NewTag"

} else {

    # Get latest tag description
    $LatestTag = git describe --tags $GitLatestRevTag

    Write-Verbose "Latest tag: $LatestTag"

    if (-not ($null = $LatestTag -match '^v([0-9]{4})\.([0-9]{2})\.([0-9]{3})$')) {

        $NewTag = $DefaultTag
        Write-Verbose "Tag doesn't match version formatting, setting default: $NewTag"

    } else {

        if ($Matches[1] -ne $Year -and $Matches[2] -ne $Month) {
       
            # New month
            $NewTag = $DefaultTag
    
        } else {
            
            # Increment build no by 1
            $NewTag = GetUniqueTag $LatestTag
        
        }

        Write-Verbose "New tag: $NewTag"
    }
}

return  $NewTag
