# Typora -> GitHub image uploader (Windows PowerShell 5.1+)
# Edit these settings before use.
$GitHubOwner = "cheesejiang"
$GitHubRepo  = "typora-images"
$GitHubBranch = "main"
$ImageFolder = "images"

$ErrorActionPreference = "Stop"

function Stop-WithMessage([string]$Message) {
    [Console]::Error.WriteLine("Typora GitHub uploader: " + $Message)
    exit 1
}

if ($GitHubOwner -eq "YOUR_GITHUB_USERNAME") {
    Stop-WithMessage "Please edit `$GitHubOwner in this script first."
}

# Typora appends one or more quoted image paths after the custom command.
$ImagePaths = @($args)
if ($ImagePaths.Count -eq 0) {
    Stop-WithMessage "No image path received. Check Typora's Custom Command configuration."
}

$TokenFile = Join-Path $env:APPDATA "TyporaGitHub\token.txt"
if (-not (Test-Path -LiteralPath $TokenFile)) {
    Stop-WithMessage "Token not configured. Follow the one-time token setup instructions."
}

try {
    $SecureToken = Get-Content -LiteralPath $TokenFile -Raw | ConvertTo-SecureString
    $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureToken)
    try {
        $Token = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }

    $Headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent" = "Typora-GitHub-Image-Uploader"
    }

    foreach ($ImagePath in $ImagePaths) {
        $ImagePath = [Environment]::ExpandEnvironmentVariables($ImagePath.Trim('"'))
        if (-not (Test-Path -LiteralPath $ImagePath -PathType Leaf)) {
            throw "Image file not found: $ImagePath"
        }

        $FileName = [IO.Path]::GetFileName($ImagePath)
        $Extension = [IO.Path]::GetExtension($FileName)
        $BaseName = [IO.Path]::GetFileNameWithoutExtension($FileName)
        $SafeName = ($BaseName -replace '[^\w.-]', '_')
        $UniqueName = "{0}_{1}{2}" -f $SafeName, (Get-Date -Format "yyyyMMdd_HHmmss_fff"), $Extension
        $RepoPath = ($ImageFolder.Trim('/') + "/" + $UniqueName).Trim('/')

        $Bytes = [IO.File]::ReadAllBytes($ImagePath)
        $Content = [Convert]::ToBase64String($Bytes)

        $Uri = "https://api.github.com/repos/$GitHubOwner/$GitHubRepo/contents/$RepoPath"
        $Body = @{
            message = "Upload image $UniqueName"
            content = $Content
            branch = $GitHubBranch
        } | ConvertTo-Json -Depth 5

        Invoke-RestMethod -Method Put -Uri $Uri -Headers $Headers -Body $Body -ContentType "application/json; charset=utf-8" | Out-Null

        # Typora reads the last N stdout lines as the URLs for N input images.
        $RawUrl = "https://raw.githubusercontent.com/$GitHubOwner/$GitHubRepo/$GitHubBranch/$RepoPath"
        [Console]::Out.WriteLine($RawUrl)
    }
}
catch {
    Stop-WithMessage $_.Exception.Message
}
finally {
    $Token = $null
}
