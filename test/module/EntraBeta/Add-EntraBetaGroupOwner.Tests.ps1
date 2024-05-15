BeforeAll {  
    if((Get-Module -Name Microsoft.Graph.Entra.Beta) -eq $null){
        Import-Module Microsoft.Graph.Entra.Beta    
    }
    Import-Module (Join-Path $psscriptroot "..\Common-Functions.ps1") -Force

    $scriptblock = {
        return @(
            [PSCustomObject]@{
                "Parameters"    = $args
            }
        )
    }  
    Mock -CommandName New-MgBetaGroupOwnerByRef -MockWith $scriptblock -ModuleName Microsoft.Graph.Entra.Beta
}

Describe "Add-EntraBetaGroupOwner" {
    Context "Test for Add-EntraBetaGroupOwner" {
        It "Should return empty object" {
            $result = Add-EntraBetaGroupOwner -ObjectId "fe4619d9-9ce7-4141-a367-ec10f3fb8af4" -RefObjectId "3015621f-bfb5-40ca-923d-8439ff7db286"
            $result | Should -BeNullOrEmpty

            Should -Invoke -CommandName New-MgBetaGroupOwnerByRef -ModuleName Microsoft.Graph.Entra.Beta -Times 1
        }

        It "Should fail when ObjectId is empty" {
            { Add-EntraBetaGroupOwner -ObjectId  -RefObjectId "3015621f-bfb5-40ca-923d-8439ff7db286"  } | Should -Throw "Missing an argument for parameter 'ObjectId'.*"
        }

        It "Should fail when ObjectId is invalid" {
            { Add-EntraBetaGroupOwner -ObjectId "" -RefObjectId "3015621f-bfb5-40ca-923d-8439ff7db286"  } | Should -Throw "Cannot bind argument to parameter 'ObjectId' because it is an empty string."
        }

        It "Should fail when RefObjectId is empty" {
            { Add-EntraBetaGroupOwner -ObjectId "fe4619d9-9ce7-4141-a367-ec10f3fb8af4" -RefObjectId   } | Should -Throw "Missing an argument for parameter 'RefObjectId'.*"
        }

        It "Should fail when RefObjectId is invalid" {
            { Add-EntraBetaGroupOwner -ObjectId "fe4619d9-9ce7-4141-a367-ec10f3fb8af4" -RefObjectId ""  } | Should -Throw "Cannot bind argument to parameter 'RefObjectId' because it is an empty string."
        }

        It "Should contain GroupId in parameters when passed ObjectId to it" {
            $result = Add-EntraBetaGroupOwner -ObjectId "fe4619d9-9ce7-4141-a367-ec10f3fb8af4" -RefObjectId "3015621f-bfb5-40ca-923d-8439ff7db286"
            $params = Get-Parameters -data $result.Parameters
            $params.GroupId | Should -Be "fe4619d9-9ce7-4141-a367-ec10f3fb8af4"
        }

        It "Should contain BodyParameter in parameters when passed RefObjectId to it" {
            $result = Add-EntraBetaGroupOwner -ObjectId "fe4619d9-9ce7-4141-a367-ec10f3fb8af4" -RefObjectId "3015621f-bfb5-40ca-923d-8439ff7db286"
            $value = @{
                "@odata.id" = "https://graph.microsoft.com/beta/users/3015621f-bfb5-40ca-923d-8439ff7db286"
            } | ConvertTo-Json -Depth 5
            $params= $result.Parameters | Convertto-json -Depth 10 | Convertfrom-json 
            $additionalProperties = $params[-1].AdditionalProperties | ConvertTo-Json -Depth 5
            $additionalProperties | Should -Be $value
        }

        It "Should contain 'User-Agent' header" {
            $userAgentHeaderValue = "PowerShell/$psVersion EntraPowershell/$entraVersion Add-EntraBetaGroupOwner"

            $result = Add-EntraBetaGroupOwner -ObjectId "fe4619d9-9ce7-4141-a367-ec10f3fb8af4" -RefObjectId "3015621f-bfb5-40ca-923d-8439ff7db286"
            $params = Get-Parameters -data $result.Parameters
            $params.Headers["User-Agent"] | Should -Be $userAgentHeaderValue
        }
    }
}        