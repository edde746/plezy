$ErrorActionPreference = 'Stop'

$url = '__PLEZYNG_RELEASE_URL__'
$checksum = '__PLEZYNG_SHA256__'

Install-ChocolateyPackage `
    -PackageName 'plezyng' `
    -FileType 'exe' `
    -SilentArgs '/SILENT /SP-' `
    -Url $url `
    -Checksum $checksum `
    -ChecksumType 'sha256'
