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
                "Id"              = "my_new_permission_grant_policy_id"
                "DeletedDateTime" = "2/8/2024 6:39:16 AM"
                "Description"     = "My new permission grant policy"
                "DisplayName"     = "My new permission grant policy"
                "Excludes"        = @{}
                "Includes"        = @("bddda1ec-0174-44d5-84e2-47fb0ac01595")
                "Parameters"      = $args
            }
        )
    }

    Mock -CommandName New-MgPolicyPermissionGrantPolicy -MockWith $scriptblock -ModuleName Microsoft.Graph.Entra
}
  
Describe "New-EntraPermissionGrantPolicy" {
    Context "Test for New-EntraPermissionGrantPolicy" {
        It "Should return created PermissionGrantPolicy" {
            $result = New-EntraPermissionGrantPolicy -Id "my_new_permission_grant_policy_id" -DisplayName "MyNewPermissionGrantPolicy" -Description "My new permission grant policy" 
            $result | Should -Not -BeNullOrEmpty
            $result.Id | should -Be "my_new_permission_grant_policy_id"
            $result.DisplayName | should -Be "My new permission grant policy"
            $result.Description | should -Be "My new permission grant policy"
            $result.Includes | should -Be @("bddda1ec-0174-44d5-84e2-47fb0ac01595")
            $result.DeletedDateTime | should -Be "2/8/2024 6:39:16 AM"

            Should -Invoke -CommandName New-MgPolicyPermissionGrantPolicy -ModuleName Microsoft.Graph.Entra -Times 1
        }
        It "Should fail when Id is empty" {
            { New-EntraPermissionGrantPolicy -Id -DisplayName "MyNewPermissionGrantPolicy" -Description "My new permission grant policy" } | Should -Throw "Missing an argument for parameter 'Id'.*"
        }
        It "Should fail when DisplayName is empty" {
            { New-EntraPermissionGrantPolicy -Id "my_new_permission_grant_policy_id"  -DisplayName -Description "My new permission grant policy" } | Should -Throw "Missing an argument for parameter 'DisplayName'.*"
        } 
        It "Should fail when Description is empty" {
            { New-EntraPermissionGrantPolicy -Id "my_new_permission_grant_policy_id"  -DisplayName "MyNewPermissionGrantPolicy" -Description } | Should -Throw "Missing an argument for parameter 'Description'.*"
        }
        It "Result should Contain ObjectId" {
            $result = New-EntraPermissionGrantPolicy -Id "my_new_permission_grant_policy_id" -DisplayName "MyNewPermissionGrantPolicy" -Description "My new permission grant policy" 
            $result.ObjectId | should -Be "my_new_permission_grant_policy_id"
        } 
        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion New-EntraPermissionGrantPolicy"

            $result = New-EntraPermissionGrantPolicy -Id "my_new_permission_grant_policy_id" -DisplayName "MyNewPermissionGrantPolicy" -Description "My new permission grant policy" 
            $params = Get-Parameters -data $result.Parameters
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }
    }
}