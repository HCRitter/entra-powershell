# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
@{
    SourceName = "Get-AzureADMSApplication"
    TargetName = $null
    Parameters = $null
    Outputs = $null
    CustomScript = @'
    PROCESS {  
    $params = @{}
    $customHeaders = New-EntraCustomHeaders -Command $MyInvocation.MyCommand
    $keysChanged = @{SearchString = "Filter"; ObjectId = "Id"}
    if($null -ne $PSBoundParameters["SearchString"])
    {
        $TmpValue = $PSBoundParameters["SearchString"]
        $Value = "displayName eq '$TmpValue' or startswith(displayName,'$TmpValue')"
        $params["Filter"] = $Value
    }
    if($null -ne $PSBoundParameters["ObjectId"])
    {
        $params["ApplicationId"] = $PSBoundParameters["ObjectId"]
    }
    if($null -ne $PSBoundParameters["Filter"])
    {
        $TmpValue = $PSBoundParameters["Filter"]
        foreach($i in $keysChanged.GetEnumerator()){
            $TmpValue = $TmpValue.Replace($i.Key, $i.Value)
        }
        $Value = $TmpValue
        $params["Filter"] = $Value
    }
    if($PSBoundParameters.ContainsKey("Verbose"))
    {
        $params["Verbose"] = $Null
    }
    if($null -ne $PSBoundParameters["All"])
    {
        if($PSBoundParameters["All"])
        {
            $params["All"] = $PSBoundParameters["All"]
        }
    }
    if($PSBoundParameters.ContainsKey("Debug"))
    {
        $params["Debug"] = $Null
    }
    if($null -ne $PSBoundParameters["Top"])
    {
        $params["Top"] = $PSBoundParameters["Top"]
    }
    if($null -ne $PSBoundParameters["WarningVariable"])
    {
        $params["WarningVariable"] = $PSBoundParameters["WarningVariable"]
    }
    if($null -ne $PSBoundParameters["InformationVariable"])
    {
        $params["InformationVariable"] = $PSBoundParameters["InformationVariable"]
    }
    if($null -ne $PSBoundParameters["InformationAction"])
    {
        $params["InformationAction"] = $PSBoundParameters["InformationAction"]
    }
    if($null -ne $PSBoundParameters["OutVariable"])
    {
        $params["OutVariable"] = $PSBoundParameters["OutVariable"]
    }
    if($null -ne $PSBoundParameters["OutBuffer"])
    {
        $params["OutBuffer"] = $PSBoundParameters["OutBuffer"]
    }
    if($null -ne $PSBoundParameters["ErrorVariable"])
    {
        $params["ErrorVariable"] = $PSBoundParameters["ErrorVariable"]
    }
    if($null -ne $PSBoundParameters["PipelineVariable"])
    {
        $params["PipelineVariable"] = $PSBoundParameters["PipelineVariable"]
    }
    if($null -ne $PSBoundParameters["ErrorAction"])
    {
        $params["ErrorAction"] = $PSBoundParameters["ErrorAction"]
    }
    if($null -ne $PSBoundParameters["WarningAction"])
    {
        $params["WarningAction"] = $PSBoundParameters["WarningAction"]
    }

    Write-Debug("============================ TRANSFORMATIONS ============================")
        $params.Keys | ForEach-Object {"$_ : $($params[$_])" } | Write-Debug
        Write-Debug("=========================================================================``n")
    
    $response = Get-MgApplication @params -Headers $customHeaders
    $response | ForEach-Object {
        if($null -ne $_) {
        Add-Member -InputObject $_ -MemberType AliasProperty -Name ObjectId -Value Id
        $propsToConvert = @(
             'AddIns','Logo','AppRoles','GroupMembershipClaims','IdentifierUris','Info',
             'IsDeviceOnlyAuthSupported','KeyCredentials','Oauth2RequirePostResponse','OptionalClaims',
             'ParentalControlSettings','PasswordCredentials','Api','PublicClient',
             'PublisherDomain','Web','RequiredResourceAccess','SignInAudience')
             
                foreach ($prop in $propsToConvert) {
                    $value = $_.$prop | ConvertTo-Json | ConvertFrom-Json
                    $_ | Add-Member -MemberType NoteProperty -Name $prop -Value ($value) -Force
                }
        }
    }

    $response
}    
'@

}