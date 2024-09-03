BeforeAll {  
    if((Get-Module -Name Microsoft.Graph.Entra.Beta) -eq $null){
        Import-Module Microsoft.Graph.Entra.Beta    
    }
    Import-Module (Join-Path $psscriptroot "..\Common-Functions.ps1") -Force

    $scriptblock = {
        return @(
            [PSCustomObject]@{
                "DisplayName"          = "new"
                "ExternalId"           = "/administrativeUnits/5bea6c93-5803-42bc-b236-7fd11570ade1"
                "Id"                   = "5bea6c93-5803-42bc-b236-7fd11570ade1"
                "Parent"               = "Microsoft.Graph.Beta.PowerShell.Models.MicrosoftGraphGovernanceResource"
                "RegisteredDateTime"   = $null
                "RegisteredRoot"       = $null
                "RoleAssignmentRequests" = @()
                "RoleAssignments"      = @()
                "RoleDefinitions"      = @()
                "RoleSettings"         = @()
                "Status"               = "Active"
                "Type"                 = "administrativeUnits"
                "AdditionalProperties" = @{"@odata.context"="https://graph.microsoft.com/beta/$metadata#governanceResources/$entity"}
                "Parameters"           = $args
            }
        )
    }    
    Mock -CommandName Get-MgBetaPrivilegedAccessResource -MockWith $scriptblock -ModuleName Microsoft.Graph.Entra.Beta
}

Describe "Get-EntraBetaMSPrivilegedResource" {
    Context "Test for Get-EntraBetaMSPrivilegedResource" {
        It "Should retrieve all resources from Microsoft Entra ID." {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles
            $result | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Get-MgBetaPrivilegedAccessResource -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when ProviderId are empty" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId } | Should -Throw "Missing an argument for parameter 'ProviderId'*"
        }

        It "Should fail when ProviderId is Invalid" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId "" } | Should -Throw "Cannot bind argument to parameter 'ProviderId' because it is an empty string."
        }

        It "Should get a specific privileged resource" {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Id "5bea6c93-5803-42bc-b236-7fd11570ade1"
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be "5bea6c93-5803-42bc-b236-7fd11570ade1"
            $result.Status | Should -Be "Active"
            $result.Type | Should -Be "administrativeUnits"
            $result.ExternalId | Should -Be "/administrativeUnits/5bea6c93-5803-42bc-b236-7fd11570ade1"
            $result.DisplayName | Should -Be "new"

            Should -Invoke -CommandName Get-MgBetaPrivilegedAccessResource -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when Id are empty" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Id } | Should -Throw "Missing an argument for parameter 'Id'*"
        }

        It "Should fail when Id is Invalid" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Id "" } | Should -Throw "Cannot bind argument to parameter 'Id' because it is an empty string."
        }

        It "Should get top privileged resources" {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Top 1
            $result | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Get-MgBetaPrivilegedAccessResource -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when Top are empty" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Top  } | Should -Throw "Missing an argument for parameter 'Top'*"
        }

        It "Should fail when Top is Invalid" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Top XYZ } | Should -Throw "Cannot process argument transformation on parameter 'Top'*"
        }

        It "Should get a specific privileged resource by filter" {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Filter "DisplayName eq 'new'"
            $result | Should -Not -BeNullOrEmpty
            $result.Id | Should -Be "5bea6c93-5803-42bc-b236-7fd11570ade1"
            $result.Status | Should -Be "Active"
            $result.Type | Should -Be "administrativeUnits"
            $result.ExternalId | Should -Be "/administrativeUnits/5bea6c93-5803-42bc-b236-7fd11570ade1"
            $result.DisplayName | Should -Be "new"

            Should -Invoke -CommandName Get-MgBetaPrivilegedAccessResource -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when Filter are empty" {
            { Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Filter  } | Should -Throw "Missing an argument for parameter 'Filter'*"
        }

        It "Should contain ObjectId in result" {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Id "5bea6c93-5803-42bc-b236-7fd11570ade1"
            $result.ObjectId | should -Be "5bea6c93-5803-42bc-b236-7fd11570ade1"
        } 

        It "Should contain GovernanceResourceId in parameters when passed Id to it" {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Id "5bea6c93-5803-42bc-b236-7fd11570ade1"
            $params = Get-Parameters -data $result.Parameters
            $params.GovernanceResourceId | Should -Be "5bea6c93-5803-42bc-b236-7fd11570ade1"

            Should -Invoke -CommandName Get-MgBetaPrivilegedAccessResource -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should contain PrivilegedAccessId in parameters when passed ProviderId to it" {
            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles -Id "5bea6c93-5803-42bc-b236-7fd11570ade1"
            $params = Get-Parameters -data $result.Parameters
            $params.PrivilegedAccessId | Should -Be "aadRoles"

            Should -Invoke -CommandName Get-MgBetaPrivilegedAccessResource -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion Get-EntraBetaMSPrivilegedResource"

            $result = Get-EntraBetaMSPrivilegedResource -ProviderId aadRoles
            $params = Get-Parameters -data $result.Parameters
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }   
    }
}