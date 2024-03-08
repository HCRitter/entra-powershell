# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
function Reset-EntraStrongAuthenticationMethodByUpn {
    <#
    .SYNOPSIS
        Resets the strong authentication method by using a user principal name.
    
    .DESCRIPTION
        The Reset-EntraStrongAuthenticationMethodByUpn cmdlet resets the strong authentication method by using a user principal name.
    
    .PARAMETER UserPrincipalName
        Specifies the user principal name for which to reset the strong authentication method.

    .PARAMETER TenantId
        Specifies the unique ID of the tenant on which to perform the operation. The default value is the tenant of the current user. This parameter applies only to partner users.   

    .PARAMETER <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https:/go.microsoft.com/fwlink/?LinkID=113216).
        
    .EXAMPLE
        Reset-EntraStrongAuthenticationMethodByUpn -UserPrincipalName Test_contoso.com#EXT#@M365x99297270.onmicrosoft.com

        Resets the strong authentication method.
    #>
    [CmdletBinding(DefaultParameterSetName = 'SetAccidentalDeletionThreshold')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][System.String] $UserPrincipalName,
        [Parameter(ParameterSetName = "SetAccidentalDeletionThreshold", ValueFromPipelineByPropertyName = $true)][System.Guid] $TenantId
        )

    PROCESS {
        if ($null -ne $PSBoundParameters["UserPrincipalName"]) {
            $userId = $PSBoundParameters.UserPrincipalName
        }
        function DeleteAuthMethod($uid, $method){
            switch ($method.AdditionalProperties['@odata.type']) {
                '#microsoft.graph.fido2AuthenticationMethod' { 
                    Remove-MgUserAuthenticationFido2Method -UserId $uid -Fido2AuthenticationMethodId $method.Id
                }
                '#microsoft.graph.emailAuthenticationMethod' { 
                    Remove-MgUserAuthenticationEmailMethod -UserId $uid -EmailAuthenticationMethodId $method.Id
                }
                '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod' { 
                    Remove-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $uid -MicrosoftAuthenticatorAuthenticationMethodId $method.Id
                }
                '#microsoft.graph.phoneAuthenticationMethod' { 
                    Remove-MgUserAuthenticationPhoneMethod -UserId $uid -PhoneAuthenticationMethodId $method.Id
                }
                '#microsoft.graph.softwareOathAuthenticationMethod' { 
                    Remove-MgUserAuthenticationSoftwareOathMethod -UserId $uid -SoftwareOathAuthenticationMethodId $method.Id
                }
                '#microsoft.graph.temporaryAccessPassAuthenticationMethod' { 
                    Remove-MgUserAuthenticationTemporaryAccessPassMethod -UserId $uid -TemporaryAccessPassAuthenticationMethodId $method.Id
                }
                '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod' { 
                    Remove-MgUserAuthenticationWindowsHelloForBusinessMethod -UserId $uid -WindowsHelloForBusinessAuthenticationMethodId $method.Id
                }
                '#microsoft.graph.passwordAuthenticationMethod' { 
                    # Password cannot be removed currently
                }        
                Default {
                    Write-Host 'This script does not handle removing this auth method type: ' + $method.AdditionalProperties['@odata.type']
                }
            }
            return $? # Return true if no error and false if there is an error
        }

        $methods = Get-MgUserAuthenticationMethod -UserId $userId
        # -1 to account for passwordAuthenticationMethod

        foreach ($authMethod in $methods) {
            $deleted = DeleteAuthMethod -uid $userId -method $authMethod
            if(!$deleted){
                # We need to use the error to identify and delete the default method.
                $defaultMethod = $authMethod
            }
        }

        # Graph API does not support reading default method of a user.
        # Plus default method can only be deleted when it is the only (last) auth method for a user.
        # We need to use the error to identify and delete the default method.
        try {
            if($null -ne $defaultMethod){
                $result = DeleteAuthMethod -uid $userId -method $defaultMethod
            }
        }
        catch {}
   
        if($null -ne $methods){
            $methods = Get-MgUserAuthenticationMethod -UserId $userId
        }
    }
}
