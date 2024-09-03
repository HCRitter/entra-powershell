# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------

BeforeAll {
    if ((Get-Module -Name Microsoft.Graph.Entra.Beta) -eq $null) {
        Import-Module Microsoft.Graph.Entra.Beta    
    }
    Import-Module (Join-Path $PSScriptRoot "..\Common-Functions.ps1") -Force

    $mockResponseScriptBlock = @"
        <TrustFrameworkPolicy xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns=""http://schemas.microsoft.com/online/cpim/schemas/2013/06"" PolicySchemaVersion=""0.3.0.0"" TenantId=""intelucre.onmicrosoft.com"" PolicyId=""B2C_1A_ProfileAdd"" PublicPolicyUri=""http://intelucre.onmicrosoft.com/B2C_1A_ProfileAdd"" TenantObjectId=""5737bf45-194f-4bc5-b209-bbbbadb4641a"">
        <BasePolicy>
            <TenantId>intelucre.onmicrosoft.com</TenantId>
            <PolicyId>B2C_1A_TrustFrameworkExtensions</PolicyId>
        </BasePolicy>
        <RelyingParty>
            <DefaultUserJourney ReferenceId=""ProfileEdit"" />
            <TechnicalProfile Id=""PolicyProfile"">
            <DisplayName>PolicyProfile123</DisplayName>
            <Protocol Name=""OpenIdConnect"" />
            <OutputClaims>
                <OutputClaim ClaimTypeReferenceId=""objectId"" PartnerClaimType=""sub"" />
                <OutputClaim ClaimTypeReferenceId=""tenantId"" AlwaysUseDefaultValue=""true"" DefaultValue=""{Policy:TenantObjectId}"" />
            </OutputClaims>
            <SubjectNamingInfo ClaimType=""sub"" />
            </TechnicalProfile>
        </RelyingParty>
        </TrustFrameworkPolicy>
"@
    $mockResponseScriptBlock = [ScriptBlock]::Create("`$args[0]")
    Mock -CommandName Invoke-GraphRequest -MockWith $mockResponseScriptBlock -ModuleName Microsoft.Graph.Entra.Beta
}
Describe "Get-EntraBetaTrustFrameworkPolicy" {
    Context "Test for Get-EntraBetaTrustFrameworkPolicy" {
        It "Should retrieve the created trust framework policies (custom policies) in the directory." {
            $result = Get-EntraBetaTrustFrameworkPolicy -Id "B2C_1A_PROFILEADD"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Contain "<PolicyId>B2C_1A_ProfileAdd</PolicyId>"

            Should -Invoke -CommandName Invoke-GraphRequest -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when Id is empty" {
            { Get-EntraBetaTrustFrameworkPolicy -Id } | Should -Throw "Missing an argument for parameter 'Id'*"
        }

        It "Should fail when Id is invalid" {
            { Get-EntraBetaTrustFrameworkPolicy -Id "" } | Should -Throw "Cannot bind argument to parameter 'Id' because it is an empty string."
        }

        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$($PSVersionTable.PSVersion) EntraPowershell/$entraVersion Get-EntraBetaTrustFrameworkPolicy"

            $result = Get-EntraBetaTrustFrameworkPolicy -Id "B2C_1A_PROFILEADD"
            
            # Assuming Get-Parameters is supposed to fetch the headers from the mocked command
            $params = @{
                Headers = @{
                    "User-Agent" = "PowerShell/$($PSVersionTable.PSVersion) EntraPowershell/$entraVersion Get-EntraBetaTrustFrameworkPolicy"
                }
            }
            
            $params.Headers["User-Agent"] | Should -Contain $userAgentHeaderValue
        }   
        
        It "Should execute successfully without throwing an error " {
            # Disable confirmation prompts       
            $originalDebugPreference = $DebugPreference
            $DebugPreference = 'Continue'
    
            try {
                # Act & Assert: Ensure the function doesn't throw an exception
                { Get-EntraBetaTrustFrameworkPolicy -Id "B2C_1A_PROFILEADD" -Debug } | Should -Not -Throw
            } finally {
                # Restore original confirmation preference            
                $DebugPreference = $originalDebugPreference        
            }
        }
    }
}
