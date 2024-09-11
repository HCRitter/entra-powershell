# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
@{
    SourceName = "Remove-AzureADServiceAppRoleAssignment"
    TargetName = "Remove-MgServicePrincipalAppRoleAssignment"
    Parameters = @(
        @{
            SourceName = "ServicePrincipalId"
            TargetName = "ServicePrincipalId"
            ConversionType = "Name"
            SpecialMapping = $null
        }
    )
    Outputs = $null
}