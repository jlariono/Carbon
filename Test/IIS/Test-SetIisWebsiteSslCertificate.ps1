# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$siteName = 'Carbon-Set-IisWebsiteSslCertificate'
$cert = $null
$appID = '990ae75d-b1c3-4c4e-93f2-9b22dfbfe0ca'
$ipPort = '43.27.98.0:443'
$allPort = '8013'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings @( "https/$ipPort`:", "https/*:$allPort`:" )
    $cert = Install-Certificate -Path (Join-Path $TestDir ..\Certificates\CarbonTestCertificate.cer -Resolve) -StoreLocation LocalMachine -StoreName My
}

function TearDown
{
    Remove-Certificate -Certificate $cert -StoreLocation LocalMachine -StoreName My
    Uninstall-IisWebsite -Name $siteName
    Remove-Module Carbon
}

function Test-ShouldSetWebsiteSslCertificate
{
    Set-IisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID
    try
    {
        $binding = Get-SslCertificateBinding -IPPort $ipPort
        Assert-NotNull $binding
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
        Assert-Equal $appID $binding.ApplicationID
        
        $binding = Get-SslCertificateBinding -IPPort "0.0.0.0:$allPort"
        Assert-NotNull $binding
        Assert-Equal $cert.Thumbprint $binding.CertificateHash
        Assert-Equal $appID $binding.ApplicationID
        
    }
    finally
    {
        Remove-SslCertificateBinding -IPPort $ipPort
        Remove-SslCertificateBinding -IPPort "0.0.0.0:$allPort"
    } 
}

function Test-ShouldSupportWhatIf
{
    $bindings = @( Get-SslCertificateBindings )
    Set-IisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID -WhatIf
    $newBindings = @( Get-SslCertificateBindings )
    Assert-Equal $bindings.Length $newBindings.Length
}

function Test-ShouldSupportWebsiteWithoutSslBindings
{
    Install-IisWebsite -Name $siteName -Path $TestDir -Bindings @( 'http/*:80:' )
    $bindings = @( Get-SslCertificateBindings )
    Set-IisWebsiteSslCertificate -SiteName $siteName -Thumbprint $cert.Thumbprint -ApplicationID $appID
    $newBindings = @( Get-SslCertificateBindings )
    Assert-Equal $bindings.Length $newBindings.Length
}
