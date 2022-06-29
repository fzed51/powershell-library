$PhpVersions = Invoke-WebRequest "https://www.php.net/releases/?json" `
| Select-Object -ExpandProperty Content `
| convertfrom-json

$PhpSupportedVersions = $PhpVersions | Get-Member `
| Select-Object -ExpandProperty Name `
| Where-Object { $_ -match "\d+" } `
| ForEach-Object {
    $PhpVersions.$_ | Select-Object -ExpandProperty supported_versions
}

$PhpLastSupportedVersion = $PhpSupportedVersions | ForEach-Object {
    Invoke-WebRequest "https://www.php.net/releases/?json&version=$_" `
    | Select-Object -ExpandProperty Content `
    | convertfrom-json `
    | Select-Object -ExpandProperty version
}

return $PhpLastSupportedVersion