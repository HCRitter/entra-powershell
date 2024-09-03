# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------

BeforeAll {  
    if((Get-Module -Name Microsoft.Graph.Entra.Beta) -eq $null){
        Import-Module Microsoft.Graph.Entra.Beta    
    }
    Import-Module (Join-Path $psscriptroot "..\Common-Functions.ps1") -Force

    $scriptblock = {
        return @{
            '@odata.type'                            = '#microsoft.graph.servicePrincipal'
            'accountEnabled'                         = $true
            'alternativeNames'                       = @{}
            'createdDateTime'                        = '2023-09-21T15:31:24Z'
            'appDisplayName'                         = 'ToGraph_443democc3c'
            'appId'                                  = '7bc6f57b-9014-45de-a73c-5a2b75454305'
            'applicationTemplateId'                  = '1cdcd90d-0bf2-4bb8-bc20-a3f5b30b251e'
            'appOwnerOrganizationId'                 = 'd5aec55f-2d12-4442-8d2f-ccca95d4390e'
            'appRoleAssignmentRequired'              = $true
            'displayName'                            = 'ToGraph_443democc3c'
            'homepage'                               = 'https://*.time2work.com/Security/ADFS.aspx?metadata=nimbus|ISV9.2|primary|z'
            'isAuthorizationServiceEnabled'          = $false
            'notificationEmailAddresses'             = @{}
            'publisherName'                          = 'Contoso'
            'replyUrls'                              = @{}
            'samlSLOBindingType'                     = 'httpRedirect'
            'servicePrincipalNames'                  = @('7bc6f57b-9014-45de-a73c-5a2b75454305')
            'servicePrincipalType'                   = 'Application'
            'signInAudience'                         = 'AzureADMyOrg'
            'tags'                                   = @('WindowsAzureActiveDirectoryIntegratedApp')
            'addIns'                                 = @{}
            'api'                                    = @{ 'resourceSpecificApplicationPermissions' = @() }
            'appRoles'                               = @(
                @{
                    'allowedMemberTypes'          = @('User')
                    'description'                 = 'msiam_access'
                    'displayName'                 = 'msiam_access'
                    'id'                          = '643985ce-3eaf-4a67-9550-ecca25cb6814'
                    'isEnabled'                   = $true
                    'origin'                      = 'Application'
                    'isPreAuthorizationRequired'  = $false
                    'isPrivate'                   = $false
                }
            )
            'info'                                   = @{ 'logoUrl' = 'https://aadcdn.msftauthimages.net/c1c6b6c8-to49lv6wypmt9nbj9h-yeqnpoxuawhueygc1g-lkdu4/appbranding/wpnyxydq3vlekihhtujmmyy8n-0-4cx9y7wm-d9z4q/1033/bannerlogo?ts=638493625239351699' }
            'keyCredentials'                         = @{}
            'publishedPermissionScopes'              = @{}
            'passwordCredentials'                    = @{}
            'resourceSpecificApplicationPermissions' = @{}
            'verifiedPublisher'                      = @{}
            'ObjectId'                               = '02939955-b5d0-436e-a8b1-35d37154f550'
            'DeletedDateTime'                        = $null
            'Id'                                     = '02939955-b5d0-436e-a8b1-35d37154f550'
            'AdditionalProperties'                   = @{
                '@odata.type'                            = '#microsoft.graph.servicePrincipal'
                'accountEnabled'                         = $true
                'alternativeNames'                       = @{}
                'createdDateTime'                        = '2023-09-21T15:31:24Z'
                'appDisplayName'                         = 'ToGraph_443democc3c'
                'appId'                                  = '7bc6f57b-9014-45de-a73c-5a2b75454305'
                'applicationTemplateId'                  = '1cdcd90d-0bf2-4bb8-bc20-a3f5b30b251e'
                'appOwnerOrganizationId'                 = 'd5aec55f-2d12-4442-8d2f-ccca95d4390e'
                'appRoleAssignmentRequired'              = $true
                'displayName'                            = 'ToGraph_443democc3c'
                'homepage'                               = 'https://*.time2work.com/Security/ADFS.aspx?metadata=nimbus|ISV9.2|primary|z'
                'isAuthorizationServiceEnabled'          = $false
                'notificationEmailAddresses'             = @{}
                'publisherName'                          = 'Contoso'
                'replyUrls'                              = @{}
                'samlSLOBindingType'                     = 'httpRedirect'
                'servicePrincipalNames'                  = @('7bc6f57b-9014-45de-a73c-5a2b75454305')
                'servicePrincipalType'                   = 'Application'
                'signInAudience'                         = 'AzureADMyOrg'
                'tags'                                   = @('WindowsAzureActiveDirectoryIntegratedApp')
                'addIns'                                 = @{}
                'api'                                    = @{ 'resourceSpecificApplicationPermissions' = @() }
                'appRoles'                               = @{}
                'info'                                   = @{ 'logoUrl' = 'https://aadcdn.msftauthimages.net/c1c6b6c8-to49lv6wypmt9nbj9h-yeqnpoxuawhueygc1g-lkdu4/appbranding/wpnyxydq3vlekihhtujmmyy8n-0-4cx9y7wm-d9z4q/1033/bannerlogo?ts=638493625239351699' }
                'keyCredentials'                         = @{}
                'publishedPermissionScopes'              = @{}
                'passwordCredentials'                    = @{}
                'resourceSpecificApplicationPermissions' = @{}
                'verifiedPublisher'                      = @{}
            }
            "Parameters"                                 = $args
        }
    }    
    Mock -CommandName Get-MgBetaServicePrincipalOwnedObject -MockWith $scriptblock -ModuleName Microsoft.Graph.Entra.Beta
}

Describe "Get-EntraBetaServicePrincipalOwnedObject" {
    Context "Test for Get-EntraBetaServicePrincipalOwnedObject" {
        It "Should retrieve the owned objects of a service principal" {
            $result = Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3"
            $result | Should -Not -BeNullOrEmpty
            $result.AdditionalProperties | Should -Not -BeNullOrEmpty
            $result.displayName | Should -Be "ToGraph_443democc3c"
            $result.appDisplayName | Should -Be "ToGraph_443democc3c"
            $result.Id | Should -Be "02939955-b5d0-436e-a8b1-35d37154f550"
            $result.appId | Should -Be "7bc6f57b-9014-45de-a73c-5a2b75454305"
            $result.AdditionalProperties.appDisplayName | Should -Be "ToGraph_443democc3c"
            $result.AdditionalProperties.tags | Should -Be @('WindowsAzureActiveDirectoryIntegratedApp')

            Should -Invoke -CommandName Get-MgBetaServicePrincipalOwnedObject -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when ObjectId are empty" {
            { Get-EntraBetaServicePrincipalOwnedObject -ObjectId } | Should -Throw "Missing an argument for parameter 'ObjectId'*"
        }

        It "Should fail when ObjectId is Invalid" {
            { Get-EntraBetaServicePrincipalOwnedObject -ObjectId "" } | Should -Throw "Cannot bind argument to parameter 'ObjectId' because it is an empty string."
        }

        It "Should return top service principal" {
            $result = Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3" -Top 1
            $result | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Get-MgBetaServicePrincipalOwnedObject -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when Top are empty" {
            { Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3" -Top  } | Should -Throw "Missing an argument for parameter 'Top'*"
        }

        It "Should fail when Top is Invalid" {
            { Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3" -Top XYZ } | Should -Throw "Cannot process argument transformation on parameter 'Top'*"
        }

        It "Should return all service principal" {
            $result = Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3" -All
            $result | Should -Not -BeNullOrEmpty

            Should -Invoke -CommandName Get-MgBetaServicePrincipalOwnedObject -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when All has an argument" {
            { Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3" -All $true } | Should -Throw "A positional parameter cannot be found that accepts argument 'True'."
        }

        It "Should contain Id in result" {
            $result = Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3"
            $result.Id | should -Be "02939955-b5d0-436e-a8b1-35d37154f550"

            Should -Invoke -CommandName Get-MgBetaServicePrincipalOwnedObject -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        } 

        It "Should contain ServicePrincipalId in parameters when passed Id to it" {
            $result = Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3"
            $params = Get-Parameters -data $result.Parameters
            $params.ServicePrincipalId | Should -Be "2d028fff-7e65-4340-80ca-89be16dae0b3"
        }

        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion Get-EntraBetaServicePrincipalOwnedObject"
            $result = Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3"
            $params = Get-Parameters -data $result.Parameters
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }  
        
        It "Should execute successfully without throwing an error " {
            # Disable confirmation prompts       
            $originalDebugPreference = $DebugPreference
            $DebugPreference = 'Continue'
    
            try {
                # Act & Assert: Ensure the function doesn't throw an exception
                { Get-EntraBetaServicePrincipalOwnedObject -ObjectId "2d028fff-7e65-4340-80ca-89be16dae0b3" -Debug } | Should -Not -Throw
            } finally {
                # Restore original confirmation preference            
                $DebugPreference = $originalDebugPreference        
            }
        }
    }
}