# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
BeforeAll {  
    if((Get-Module -Name Microsoft.Graph.Entra) -eq $null){
        Import-Module Microsoft.Graph.Entra      
    }
    Import-Module (Join-Path $psscriptroot "..\Common-Functions.ps1") -Force
    
    $scriptblock = {
        return @(
            [PSCustomObject]@{
              "Id"                           = "ffffffff-5555-6666-7777-aaaaaaaaaaaa"
              "DeletedDateTime"              = $null
              "AdditionalProperties"         = @{
                                                    "@odata.type"            = "#microsoft.graph.device"
                                                    "accountEnabled"         = $true
                                                    "deviceId"               = "00001111-aaaa-2222-bbbb-3333cccc4444"
                                                    "displayName"            = "Mock-App"
                                                    "isCompliant"            = $false
                                                    "isManaged"              = $true
                                                    "operatingSystem"        = "WINDOWS"
                                                    "operatingSystemVersion" = "10.0.22621.1700"
                                                    "systemLabels"           = @{}
                                                    "extensionAttributes"    = $null
                                                 }
              "Parameters"                   = $args
            }
        )
    }

    Mock -CommandName Get-MgUserRegisteredDevice -MockWith $scriptblock -ModuleName Microsoft.Graph.Entra
}

Describe "Get-EntraUserRegisteredDevice" {
Context "Test for Get-EntraUserRegisteredDevice" {
        It "Should return specific user registered device" {
            $result = Get-EntraUserRegisteredDevice -ObjectId "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb"
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be "ffffffff-5555-6666-7777-aaaaaaaaaaaa"
            $result.AdditionalProperties.deviceId | Should -Be "00001111-aaaa-2222-bbbb-3333cccc4444"
            $result.AdditionalProperties.displayName | Should -Be "Mock-App"

            Should -Invoke -CommandName Get-MgUserRegisteredDevice  -ModuleName Microsoft.Graph.Entra -Times 1
        }
        It "Should fail when ObjectlId is empty" {
            { Get-EntraUserRegisteredDevice -ObjectId    } | Should -Throw "Missing an argument for parameter 'ObjectId'*"
        }
        It "Should fail when ObjectlId is invalid" {
            { Get-EntraUserRegisteredDevice -ObjectId  ""} | Should -Throw "Cannot bind argument to parameter 'ObjectId' because it is an empty string."
        }
        It "Should return All user registered devices" {
            $result = Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -All
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be "ffffffff-5555-6666-7777-aaaaaaaaaaaa"
            $result.AdditionalProperties.deviceId | Should -Be "00001111-aaaa-2222-bbbb-3333cccc4444"
            $result.AdditionalProperties.displayName | Should -Be "Mock-App"

            Should -Invoke -CommandName Get-MgUserRegisteredDevice  -ModuleName Microsoft.Graph.Entra -Times 1
        }
        It "Should fail when All is invalid" {
            { Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -All xyz } | Should -Throw "A positional parameter cannot be found that accepts argument 'xyz'.*"
        }
        It "Should return top 1 user registered device" {
            $result = Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -Top 1
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be "ffffffff-5555-6666-7777-aaaaaaaaaaaa"
            $result.AdditionalProperties.deviceId | Should -Be "00001111-aaaa-2222-bbbb-3333cccc4444"
            $result.AdditionalProperties.displayName | Should -Be "Mock-App"

            Should -Invoke -CommandName Get-MgUserRegisteredDevice  -ModuleName Microsoft.Graph.Entra -Times 1
        }
        It "Should fail when Top is empty" {
            { Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -Top } | Should -Throw "Missing an argument for parameter 'Top'*"
        }
        It "Should fail when Top is invalid" {
            { Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -Top xyz } | Should -Throw "Cannot process argument transformation on parameter 'Top'*"
        }
        It "Property parameter should work" {
            $result = Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -Property DisplayName
            $result | Should -Not -BeNullOrEmpty
            $result.AdditionalProperties.displayName | Should -Be "Mock-App"

            Should -Invoke -CommandName Get-MgUserRegisteredDevice -ModuleName Microsoft.Graph.Entra -Times 1
        }
        It "Should fail when Property is empty" {
             { Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -Property } | Should -Throw "Missing an argument for parameter 'Property'*"
        }
        It "Should contain UserId in parameters when passed ObjectId to it" {              
            $result = Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb"
            $params = Get-Parameters -data $result.Parameters
            $params.UserId | Should -Be "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb"
        }
        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion Get-EntraUserRegisteredDevice"

            $result = Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb"
            $params = Get-Parameters -data $result.Parameters
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }
        It "Should execute successfully without throwing an error " {
            # Disable confirmation prompts       
            $originalDebugPreference = $DebugPreference
            $DebugPreference = 'Continue'

            try {
                # Act & Assert: Ensure the function doesn't throw an exception
                { Get-EntraUserRegisteredDevice -ObjectId  "aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb" -Debug } | Should -Not -Throw
            } finally {
                # Restore original confirmation preference            
                $DebugPreference = $originalDebugPreference        
            }
        }

    }
}
 