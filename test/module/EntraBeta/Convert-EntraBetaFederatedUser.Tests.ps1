# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
BeforeAll {  
    if((Get-Module -Name Microsoft.Graph.Entra.Beta) -eq $null){
        Import-Module Microsoft.Graph.Entra.Beta      
    }
    Import-Module (Join-Path $psscriptroot "..\Common-Functions.ps1") -Force
     $scriptblockForAuthenticationMethod = {
            return @(
                [PSCustomObject]@{
                    "Id" = "00aa00aa-bb11-cc22-dd33-44ee44ee44ee"
                }        
        )   
     }      
     $scriptblockForMgUser= {
        return @(
            [PSCustomObject]@{
                "Id" = "22cc22cc-dd33-ee44-ff55-66aa66aa66aa"
            }        
    )   
 }  

    Mock -CommandName Get-MgBetaUserAuthenticationMethod -MockWith $scriptblockForAuthenticationMethod -ModuleName Microsoft.Graph.Entra.Beta
    Mock -CommandName Get-MgBetaUser -MockWith $scriptblockForMgUser -ModuleName Microsoft.Graph.Entra.Beta
    Mock -CommandName Reset-MgBetaUserAuthenticationMethodPassword -MockWith {} -ModuleName Microsoft.Graph.Entra.Beta
}
 
    Describe "Convert-EntraBetaFederatedUser" {
    Context "Test for Convert-EntraBetaFederatedUser" {
        It "Should sets identity synchronization features for a tenant" {
            $result = Convert-EntraBetaFederatedUser -UserPrincipalName "xyz.onmicrosoft.com" -NewPassword "Pass1234"
            $result | Should -BeNullOrEmpty
            Should -Invoke -CommandName Reset-MgBetaUserAuthenticationMethodPassword -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }
        It "Should fail when UserPrincipalName is empty" {
            {Convert-EntraBetaFederatedUser -UserPrincipalName } | Should -Throw "Missing an argument for parameter 'UserPrincipalName'. Specify a parameter*"
        }
        It "Should fail when UserPrincipalName is invalid" {
            {Convert-EntraBetaFederatedUser -UserPrincipalName ""} | Should -Throw "Cannot bind argument to parameter 'UserPrincipalName' because it is an empty string*"
        }
        It "Should fail when NewPassword is empty" {
            { Convert-EntraBetaFederatedUser -UserPrincipalName "xyz.onmicrosoft.com" -NewPassword  } | Should -Throw "Missing an argument for parameter 'NewPassword'. Specify a parameter*"
        }
        It "Should contain 'User-Agent' header" {

            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion Convert-EntraBetaFederatedUser"
            Mock -CommandName Reset-MgBetaUserAuthenticationMethodPassword -MockWith {$args} -ModuleName Microsoft.Graph.Entra.Beta
        
            $result =Convert-EntraBetaFederatedUser -UserPrincipalName "xyz.onmicrosoft.com" -NewPassword "Pass1234"
            $params = Get-Parameters -data $result
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }
        It "Should execute successfully without throwing an error" {
            # Disable confirmation prompts       
            $originalDebugPreference = $DebugPreference
            $DebugPreference = 'Continue'
    
            try {
                # Act & Assert: Ensure the function doesn't throw an exception
                { Convert-EntraBetaFederatedUser -UserPrincipalName "xyz.onmicrosoft.com" -NewPassword "Pass1234" -Debug } | Should -Not -Throw
            } finally {
                # Restore original confirmation preference            
                $DebugPreference = $originalDebugPreference        
            }
        }
    }
} 