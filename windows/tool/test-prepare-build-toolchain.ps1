# Exercise the fail-closed file verification without installing tools or requiring
# Windows trust APIs. Actual publisher signatures are independently verified when
# reviewing the locked downloads; production always calls the Windows trust API.
#requires -Version 7.2
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'prepare-build-toolchain.ps1'
$tokens = $null
$errors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors | Out-String) }
$function = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-PinnedFile' }, $true)
if (-not $function) { throw 'Pinned-file verifier is missing.' }
. ([scriptblock]::Create($function.Extent.Text))
$innoVerifier = $ast.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Assert-InnoCompilerVersion' }, $true)
if (-not $innoVerifier) { throw 'Inno compiler engine verifier is missing.' }
. ([scriptblock]::Create($innoVerifier.Extent.Text))
$script:innoProbe = [pscustomobject]@{ ExitCode = 0; Output = "Compiler engine version: Inno Setup 6.7.3`r`nSuccessful compile. Output was disabled." }
function Invoke-InnoCompilerProbe { param([string]$Path) return $script:innoProbe }

$directory = Join-Path ([IO.Path]::GetTempPath()) ('plezy-toolchain-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $directory | Out-Null
$rsa = [Security.Cryptography.RSA]::Create(2048)
$request = [Security.Cryptography.X509Certificates.CertificateRequest]::new('CN=Toolchain Test Publisher', $rsa, [Security.Cryptography.HashAlgorithmName]::SHA256, [Security.Cryptography.RSASignaturePadding]::Pkcs1)
$certificate = $request.CreateSelfSigned([DateTimeOffset]::UtcNow.AddMinutes(-1), [DateTimeOffset]::UtcNow.AddDays(1))
$script:signatureStatus = 'Valid'
$script:signatureCalls = 0
function Get-AuthenticodeSignature {
    param([string]$LiteralPath)
    $script:signatureCalls++
    return [pscustomobject]@{ Status = $script:signatureStatus; SignerCertificate = $certificate }
}
function Expect-Rejection([scriptblock]$Action, [string]$Message) {
    try { & $Action } catch {
        if ($_.Exception.Message -notlike $Message) { throw }
        return
    }
    throw "Expected rejection matching: $Message"
}
try {
    $file = Join-Path $directory 'fixture.exe'
    [IO.File]::WriteAllText($file, 'reviewed fixture')
    $pin = [pscustomobject]@{ sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant(); authenticodePublisher = 'Toolchain Test Publisher' }
    Assert-PinnedFile $file $pin
    if ($script:signatureCalls -ne 1) { throw 'Valid-file signature was not checked.' }
    [IO.File]::AppendAllText($file, 'tampered')
    Expect-Rejection { Assert-PinnedFile $file $pin } 'SHA-256 mismatch*'
    if ($script:signatureCalls -ne 1) { throw 'Tampered bytes reached signature verification.' }
    [IO.File]::WriteAllText($file, 'reviewed fixture')
    $script:signatureStatus = 'NotSigned'
    Expect-Rejection { Assert-PinnedFile $file $pin } 'Invalid Authenticode signature*'
    $script:signatureStatus = 'Valid'
    $pin.authenticodePublisher = 'Different Publisher'
    Expect-Rejection { Assert-PinnedFile $file $pin } 'Unexpected publisher*'
    Assert-InnoCompilerVersion $file '6.7.3'
    Expect-Rejection { Assert-InnoCompilerVersion $file '6.7.2' } 'Unexpected Inno compiler engine version*'
    $script:innoProbe.Output = "Compiler engine version: Inno Setup 6.7.3`nCompiler engine version: Inno Setup 6.7.3"
    Expect-Rejection { Assert-InnoCompilerVersion $file '6.7.3' } 'Unexpected Inno compiler engine version*'
    $script:innoProbe.Output = 'Inno Setup 6 Command-Line Compiler'
    Expect-Rejection { Assert-InnoCompilerVersion $file '6.7.3' } 'Unexpected Inno compiler engine version*'
    $script:innoProbe.ExitCode = 2
    Expect-Rejection { Assert-InnoCompilerVersion $file '6.7.3' } 'The pinned Inno compiler probe failed*'
    Remove-Item -LiteralPath $file
    Expect-Rejection { Assert-PinnedFile $file $pin } 'Missing pinned tool*'
    Expect-Rejection { Assert-InnoCompilerVersion $file '6.7.3' } 'Missing installed tool*'
    Write-Host 'Pinned Windows download rejection checks passed (hash, signature, publisher, missing file).'
    Write-Host 'Inno engine version checks passed (exact version, mismatch, duplicate, missing version, compiler failure).'
} finally {
    $certificate.Dispose()
    $rsa.Dispose()
    Remove-Item -LiteralPath $directory -Recurse -Force
}
