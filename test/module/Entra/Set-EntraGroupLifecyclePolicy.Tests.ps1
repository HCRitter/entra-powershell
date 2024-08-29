# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
BeforeAll {  
    if ((Get-Module -Name Microsoft.Graph.Entra) -eq $null) {
        Import-Module Microsoft.Graph.Entra      
    }
    Import-Module (Join-Path $psscriptroot "..\Common-Functions.ps1") -Force
    
    $scriptblock = {
        return @(
            [PSCustomObject]@{
                "Id"                          = "22cc22cc-dd33-ee44-ff55-66aa66aa66aa"
                "AlternateNotificationEmails" = "admingroup@contoso.com"
                "GroupLifetimeInDays"         = "100"
                "ManagedGroupTypes"           = "All"
                "Parameters"                  = $args
            }
        )
    }

    Mock -CommandName Update-MgGroupLifecyclePolicy -MockWith $scriptblock -ModuleName Microsoft.Graph.Entra
}
  
Describe "Set-EntraGroupLifecyclePolicy " {
    Context "Test for Set-EntraGroupLifecyclePolicy" {
        It "Should return updated GroupLifecyclePolicy" {
            $result = Set-EntraGroupLifecyclePolicy -Id a47d4510-08c8-4437-99e9-71ca88e7af0f -GroupLifetimeInDays 200 -AlternateNotificationEmails "admingroup@contoso.com" -ManagedGroupTypes "All"
            $result | Should -Not -BeNullOrEmpty
            $result.Id | should -Be "22cc22cc-dd33-ee44-ff55-66aa66aa66aa"
            $result.GroupLifetimeInDays | should -Be "100"
            $result.ManagedGroupTypes | should -Be "All"
            $result.AlternateNotificationEmails | should -Be "admingroup@contoso.com"

            Should -Invoke -CommandName Update-MgGroupLifecyclePolicy -ModuleName Microsoft.Graph.Entra -Times 1
        }
        It "Should fail when Id is invalid" {
            { Set-EntraGroupLifecyclePolicy -Id "" -GroupLifetimeInDays a -ManagedGroupTypes "Selected" -AlternateNotificationEmails "example@contoso.com" } | Should -Throw "Cannot bind argument to parameter 'Id' because it is an empty string.*"
        }
        It "Should fail when Id is empty" {
            { Set-EntraGroupLifecyclePolicy -Id -GroupLifetimeInDays  -ManagedGroupTypes "Selected" -AlternateNotificationEmails "example@contoso.com" } | Should -Throw "Missing an argument for parameter 'Id'.*"
        } 
        It "Should fail when GroupLifetimeInDays is invalid" {
            { Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays a -ManagedGroupTypes "Selected" -AlternateNotificationEmails "example@contoso.com" } | Should -Throw "Cannot process argument transformation on parameter 'GroupLifetimeInDays'.*"
        }
        It "Should fail when GroupLifetimeInDays is empty" {
            { Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays  -ManagedGroupTypes "Selected" -AlternateNotificationEmails "example@contoso.com" } | Should -Throw "Missing an argument for parameter 'GroupLifetimeInDays'.*"
        } 
        It "Should fail when ManagedGroupTypes is empty" {
            { Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays 99 -ManagedGroupTypes  -AlternateNotificationEmails "example@contoso.com" } | Should -Throw "Missing an argument for parameter 'ManagedGroupTypes'.*"
        }
        It "Should fail when AlternateNotificationEmails is empty" {
            { Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays 99 -ManagedGroupTypes "Selected" -AlternateNotificationEmails } | Should -Throw "Missing an argument for parameter 'AlternateNotificationEmails'.*"
        }
        It "Result should Contain ObjectId" {
            $result = Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays 200 -AlternateNotificationEmails "admingroup@contoso.com" -ManagedGroupTypes "All"
            $result.ObjectId | should -Be "22cc22cc-dd33-ee44-ff55-66aa66aa66aa"
        } 
        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion Set-EntraGroupLifecyclePolicy"

            $result = Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays 200 -AlternateNotificationEmails "admingroup@contoso.com" -ManagedGroupTypes "All"
            $params = Get-Parameters -data $result.Parameters
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }
        It "Should execute successfully without throwing an error" {
            # Disable confirmation prompts       
            $originalDebugPreference = $DebugPreference
            $DebugPreference = 'Continue'

            try {
                # Act & Assert: Ensure the function doesn't throw an exception
                { Set-EntraGroupLifecyclePolicy -Id "22cc22cc-dd33-ee44-ff55-66aa66aa66aa" -GroupLifetimeInDays 200 -AlternateNotificationEmails "admingroup@contoso.com" -ManagedGroupTypes "All" -Debug } | Should -Not -Throw
            } finally {
                # Restore original confirmation preference            
                $DebugPreference = $originalDebugPreference        
            }
        }
    }
}