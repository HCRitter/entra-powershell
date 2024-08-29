# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
Set-StrictMode -Version 5
class CommandUrlMap {
    [string] $Command = $null
    [string] $URL = $null   
    [string] $Method = $null
    [DataMap[]] $Parameters = @()


    CommandUrlMap($Command, $URL, $Method, [DataMap[]]$Parameters){
        $this.Command = $Command
        $this.URL = $URL
        $this.Method = $Method
        $this.Parameters = $Parameters
    }

}

class ParameterMap {
    [string] $SourceName = $null
    [string] $TargetName = $null   
    [string] $ConversionType = $null
    [string] $SpecialMapping = $null  
}

class CompatibilityAdapterBuilder {
    [string] $SourceModuleName
    [string[]] $SourceModulePrefixs
    [string] $NewPrefix
    [string[]] $DestinationModuleName
    [string[]] $DestinationPrefixs
    [string] $ModuleName
    hidden [string[]] $MissingCommandsToMap = @()
    hidden [string[]] $TypesToCreate = @()
    hidden [string] $TypePrefix = ""
    hidden [hashtable] $CmdCustomizations = @{}
    hidden [hashtable] $GenericParametersTransformations = @{}
    hidden [hashtable] $GenericOutputTransformations = @{}
    hidden [hashtable] $TypeCustomizations = @{}
    hidden [string] $OutputFolder = (join-path $PSScriptRoot '../bin')
    hidden [string] $HelpFolder = $null
    hidden [MappedCmdCollection] $ModuleMap = $null
    hidden [bool] $GenerateCommandsToMapData
    hidden [hashtable] $HelperCmdletsToExport = @{}
    hidden [string] $BasePath = $null
    hidden [string] $LoadMessage
    hidden [CommandUrlMap[]] $ModuleUrlsMapping = @()
#hidden[array] $missingCmdFromURLMap=$null

    # Constructor that changes the output folder, load all the Required Modules and creates the output folder.
    CompatibilityAdapterBuilder() {  
        $this.BasePath = (join-path $PSScriptRoot '../module/Entra/')    
        $this.HelpFolder = (join-path $this.BasePath './help')
        $this.Configure((join-path $this.BasePath "/config/ModuleSettings.json"))
        $this.ConfigureURL((join-path $this.BasePath "/config/ModuleURLs.json"))

    }

    CompatibilityAdapterBuilder([string] $Module){        
        $this.BasePath = (join-path $PSScriptRoot '../module/')    
        $this.BasePath = (join-path $this.BasePath $Module)
        $this.HelpFolder = (join-path $this.BasePath './help')
        $this.Configure((join-path $this.BasePath "/config/ModuleSettings.json"))
        $this.ConfigureURL((join-path $this.BasePath "/config/ModuleURLs.json"))

    }

    CompatibilityAdapterBuilder([bool] $notRunningUT = $false){
        if($notRunningUT)
        {
            $this.BasePath = (join-path $PSScriptRoot '../module/Entra/')    
            $this.HelpFolder = (join-path $this.BasePath './help')
            $this.Configure((join-path $this.BasePath "/config/ModuleSettings.json"))
            $this.ConfigureURL((join-path $this.BasePath "/config/ModuleURLs.json"))

        }                
    }

    ConfigureURL([string] $ModuleURLsPath){

        # Read the JSON file content
        $jsonContent = Get-Content -Path $ModuleURLsPath -Raw
        
        # Convert JSON content to PowerShell objects
        $commandList = ConvertFrom-Json -InputObject $jsonContent
        
        # Convert to list of Command objects        
        foreach ($cmd in $commandList.commands) {  
            
            $paramArray = @()
        
            foreach ($param in $cmd.Parameters) {
                # $paramObj = [DataMap]::new()
                # $paramObj.Name = $param.SourceName
                # $paramObj.TargetName = $param.TargetName
                # $paramObj.ConversionType = $param.ConversionType
                # $paramObj.SpecialMapping = $param.SpecialMapping
                # $paramArray += $paramObj
 
                $paramArray += [DataMap]::New($param.SourceName, $param.TargetName, $param.ConversionType, [Scriptblock]::Create($param.SpecialMapping),
                                            $param.ParameterSetName, $param.Mandatory, $param.ValueFromPipeline, $param.ValueFromPipelineByPropertyName, $param.DataType, $param.IsURLReplaced)
            }
            
            $this.ModuleUrlsMapping += [CommandUrlMap]::New($cmd.Command, $cmd.URL, $cmd.Method, $paramArray)
        }
        
    }

    hidden Configure([string] $ModuleSettingsPath){
        $settingPath = $ModuleSettingsPath
        $content = Get-Content -Path $settingPath | ConvertFrom-Json
        $this.SourceModuleName = $content.sourceModule
        $this.SourceModulePrefixs = $content.sourceModulePrefix
        $this.NewPrefix = $content.newPrefix
        $this.DestinationModuleName = $content.destinationModuleName
        $this.DestinationPrefixs = $content.destinationPrefix
        $this.ModuleName = $content.moduleName
        $this.TypePrefix = $content.typePrefix
        Import-Module $this.SourceModuleName -Force | Out-Null
        foreach ($moduleName in $this.DestinationModuleName){
            Import-Module $moduleName -RequiredVersion $content.destinationModuleVersion -Force | Out-Null
        }

        if(!(Test-Path $this.OutputFolder)){
            New-Item -ItemType Directory -Path $this.OutputFolder | Out-Null
        }

        $this.LoadMessage = $content.loadMessage
    }

    # Generates the module then generates all the files required to create the module.
    BuildModule() {
        $this.WriteModuleFile()           
        $this.WriteModuleManifest()             
    }
    
    AddTypes($types) {
        $this.TypeCustomizations = $types
        foreach($type in $types.Keys){
            $this.TypesToCreate += $type
        }
    }

    # Add customization based on the the CommandMap object.
    AddCustomization([hashtable[]] $Commands) {
        foreach($cmd in $Commands) {
            $parameters = $null
            $outputs = $null
            if($null -ne $cmd.TargetName){
                if($cmd.Parameters){
                    $parameters = @{}
                    foreach($param in $cmd.Parameters){
                        $parameters.Add($param.SourceName, [DataMap]::New($param.SourceName, $param.TargetName, $param.ConversionType, [Scriptblock]::Create($param.SpecialMapping)))
                    }
                }
                
                if($cmd.Outputs){
                    $outputs = @{}
                    foreach($param in $cmd.Outputs){
                        $outputs.Add($param.SourceName, [DataMap]::New($param.SourceName, $param.TargetName, $param.ConversionType, [Scriptblock]::Create($param.SpecialMapping)))
                    }
                }

                $customCommand = [CommandMap]::New($cmd.SourceName,$cmd.TargetName, $parameters, $outputs)
                $this.CmdCustomizations.Add($cmd.SourceName, $customCommand)
            }
            else {
                if($cmd.Parameters){
                    $parameters = @{}
                    foreach($param in $cmd.Parameters){
                        $this.GenericParametersTransformations.Add($param.SourceName, [DataMap]::New($param.SourceName, $param.TargetName, $param.ConversionType, [Scriptblock]::Create($param.SpecialMapping)))
                    }
                }
                
                if($cmd.Outputs){
                    $outputs = @{}
                    foreach($param in $cmd.Outputs){
                        $this.GenericOutputTransformations.Add($param.SourceName, [DataMap]::New($param.SourceName, $param.TargetName, $param.ConversionType, [Scriptblock]::Create($param.SpecialMapping)))
                    }
                }

                if($null -ne $cmd.SourceName) {
                    $scriptBlock = [Scriptblock]::Create($cmd.CustomScript)
                    $customCommand = [CommandMap]::New($cmd.SourceName, $scriptBlock)
                    $this.CmdCustomizations.Add($cmd.SourceName, $customCommand)
                }
            }
        }
    }

    AddHelperCommand([string] $FileName){
        $properties = Get-ItemProperty -Path $FileName
        if($null -ne $properties){
            $name = $properties.PSChildName.Replace(".ps1","")
            $this.HelperCmdletsToExport.Add($name, $(Get-Content -Path $FileName) -join "`n")
        }
    }

    hidden GenerateHelpFiles() {
        foreach($file in Get-ChildItem -Path $this.HelpFolder -Filter "*.xml") {
            Copy-Item $file.FullName $this.OutputFolder -Force
        }
        #$helpPath = Join-Path $this.OutputFolder "$($this.ModuleName)-Help.xml"
        #$this.GetHelpHeader() | Set-Content -Path $helpPath
        #$this.GetHelpCommandsFromFiles($helpPath)
        #$this.GetHelpFooter() | Add-Content -Path $helpPath
    }

    hidden [string] GetHelpHeader() {
        $helpHeader = @"
<?xml version="1.0" encoding="utf-8"?>
<helpItems schema="maml" xmlns="http://msh">
"@
        return $helpHeader
    }

    hidden [string] GetHelpCommandsFromFiles($filePath) {
        $helpCommands = ""  
        $replacePrefix = "-" + $this.NewPrefix
        $oldPrefix = "-AzureAD"
        foreach($file in Get-ChildItem -Path $this.HelpFolder -Filter "*.xml") {
            (Get-Content $file.FullName | Select-Object -Skip 2 | Select-Object -SkipLast 1).Replace($oldPrefix,$replacePrefix) | Add-Content -Path $filePath
        }
        return $helpCommands
    }

    hidden [string] GetHelpFooter() {
        $helpHeader = @"
</helpItems>
"@
        return $helpHeader
    }
    
    hidden WriteModuleFile() {       
        $filePath = Join-Path $this.OutputFolder "$($this.ModuleName).psm1"
        #This call create the mapping used to create the final module.
        $data = $this.Map()

        $psm1FileContent = $this.GetFileHeader()
        foreach($cmd in $data.Commands) {
            $psm1FileContent += $cmd.CommandBlock
        }

        $psm1FileContent += $this.GetUnsupportedCommand()

        $psm1FileContent += $this.GetAlisesFunction()    

        # foreach($function in $this.missingCmdFromURLMap.GetEnumerator()){
        #     $psm1FileContent += $this.NewFunctionURLMap11($function,$this.ModuleUrlsMapping)
        # }

        
        foreach($function in $this.HelperCmdletsToExport.GetEnumerator()){
            $psm1FileContent += $function.Value
        }
        $psm1FileContent += $this.GetExportMemeber()        
        $psm1FileContent += $this.SetMissingCommands()
        $psm1FileContent += $this.LoadMessage
        $psm1FileContent += $this.GetTypesDefinitions()
        $psm1FileContent | Out-File -FilePath $filePath
    }

    hidden GetInnerTypes([string] $type){
        $object = New-Object -TypeName $type        
        $object.GetType().GetProperties() | ForEach-Object {
            if($_.PropertyType.Name -eq 'Nullable`1') {
                $name = $_.PropertyType.GenericTypeArguments.FullName
                if(!$_.PropertyType.GenericTypeArguments.IsEnum){
                    if($name -like "$($this.TypePrefix)*") {    
                        if(!$this.TypesToCreate.Contains($name)){
                            $this.TypesToCreate += $name
                            $this.GetInnerTypes($name)
                        }           
                    }
                }
            }
            elseif($_.PropertyType.Name -eq 'List`1') {
                $name = $_.PropertyType.GenericTypeArguments.FullName
                if(!$_.PropertyType.GenericTypeArguments.IsEnum){                
                    if($name -like "$($this.TypePrefix)*") {    
                        if(!$this.TypesToCreate.Contains($name)){
                            $this.TypesToCreate += $name
                            $this.GetInnerTypes($name)
                        }           
                    }
                }
            }
            else {
                if(!$_.PropertyType.IsEnum){                    
                    $name = $_.PropertyType.FullName
                    if($name -like "$($this.TypePrefix)*") {                        
                        if(!$this.TypesToCreate.Contains($name)){
                            $this.TypesToCreate += $name
                            $this.GetInnerTypes($name)
                        }
                    }
                }
            }  
        }
    }

    hidden [string] GetTypesDefinitions() {
        $types = $this.TypesToCreate | Sort-Object -Unique
        
        foreach($type in $types) {
            $this.GetInnerTypes($type)
        }

        $types = $this.TypesToCreate | Sort-Object -Unique        
        $namespace = $null
        $def = @"
# ------------------------------------------------------------------------------
# Type definitios required for commands inputs
# ------------------------------------------------------------------------------

`$def = @"

"@
        Write-Host "Creating types definitions for $($types.Count) types."
        foreach($type in $types) {
        Write-Host "- Generating type for $type"
        if($type.contains("+")){
            $type = $type.Substring(0,$type.IndexOf("+"))
            Write-Host "- Real type is $type"
        }
        $object = New-Object -TypeName $type
        $namespaceNew = $object.GetType().Namespace
        $enumsDefined = @()

        if($namespace -ne $namespaceNew){
            if($null -ne $namespace){
                $def += @"
}

namespace  $namespaceNew
{

    using System.Linq;

"@
            }
            else {
                $def += @"

namespace  $namespaceNew
{

    using System.Linq;
    
"@        
            }
            $namespace = $object.GetType().Namespace
        }

        $name = $object.GetType().Name
        if($object.GetType().IsEnum){ 
            $name = $object.GetType().Name
            if(!$enumsDefined.Contains($name)){
                $def += $this.GetEnumString($name, $object.GetType().FullName)
                $enumsDefined += $name
                continue
            }                    
        }
        $def += @"
    public class $name
    {

"@

        if($this.TypeCustomizations.ContainsKey($object.GetType().FullName)){
            $extraFunctions = $this.TypeCustomizations[$object.GetType().FullName]
            $def += @"
$extraFunctions
    }

"@
        }
        else {
                    
        $object.GetType().GetProperties() | ForEach-Object {   
            if($_.PropertyType.Name -eq 'Nullable`1') {
                $name = $_.PropertyType.GenericTypeArguments.FullName
                if($_.PropertyType.GenericTypeArguments.IsEnum){                    
                    $name = $_.PropertyType.GenericTypeArguments.Name
                    if(!$enumsDefined.Contains($name)){
                        $def += $this.GetEnumString($name, $_.PropertyType.GenericTypeArguments.FullName)
                        $enumsDefined += $name
                    }                    
                }
                $name = "System.Nullable<$($name)>"
            }
            elseif ($_.PropertyType.Name -eq 'List`1') {
                $name = $_.PropertyType.GenericTypeArguments.FullName
                if($_.PropertyType.GenericTypeArguments.IsEnum){
                    $name = $_.PropertyType.GenericTypeArguments.Name
                    if(!$enumsDefined.Contains($name)){
                        $def += $this.GetEnumString($name, $_.PropertyType.GenericTypeArguments.FullName)
                        $enumsDefined += $name
                    }
                }
                $name = "System.Collections.Generic.List<$($name)>"
            }
            else {
                $name = $_.PropertyType.FullName
                if($_.PropertyType.IsEnum){
                    $name = $_.PropertyType.Name
                    if(!$enumsDefined.Contains($name)){
                        $def += $this.GetEnumString($name, $_.PropertyType.FullName)
                        $enumsDefined += $name
                    }
                }                
            }  
            $def += "        public $($name) $($_.Name);`n"  
        }

        $constructor = ""

        if(1 -eq $object.GetType().GetProperties().Count){

            $constructor = @"
public $($object.GetType().Name)()
        {        
        }
        
        public $($object.GetType().Name)($name value)
        {
            $($object.GetType().GetProperties()[0].Name) = value;
        }
"@
        }

        $def += @"
        $constructor
    }

"@
        }
    }

    $def += @"    
}
"@

        $def += @"

`"@
    try{ Add-Type -TypeDefinition `$def }
    catch{}

# ------------------------------------------------------------------------------
# End of Type definitios required for commands inputs
# ------------------------------------------------------------------------------
"@

        return $def
    }

    hidden [string] GetEnumString([string] $enumName, [string] $enumType) {
        $def += @"
        public enum $($enumName){

"@
            [enum]::getvalues([type]$enumType) | ForEach-Object { 
                $def += "            $_ = $($_.value__),`n"
            }
            $def += @"           
        }

"@        
        return $def
    }

    hidden WriteModuleManifest() {
        $settingPath = join-path $this.BasePath "./config/ModuleMetadata.json"        
        $files = @("$($this.ModuleName).psd1", "$($this.ModuleName).psm1", "$($this.ModuleName)-Help.xml")
        $content = Get-Content -Path $settingPath | ConvertFrom-Json
        $PSData = @{
            Tags = $($content.tags)
            LicenseUri = $($content.licenseUri)
            ProjectUri = $($content.projectUri)
            IconUri = $($content.iconUri)
            ReleaseNotes = $($content.releaseNotes)
            Prerelease = $null
        }
        $manisfestPath = Join-Path $this.OutputFolder "$($this.ModuleName).psd1"
        $functions = $this.ModuleMap.CommandsList + "Enable-EntraAzureADAlias" + "Get-EntraUnsupportedCommand"
        $requiredModules = @()
        foreach($module in $content.requiredModules){
            $requiredModules += @{ModuleName = $module; ModuleVersion = $content.requiredModulesVersion}
        }
        $moduleSettings = @{
            Path = $manisfestPath
            GUID = $($content.guid)
            ModuleVersion = "$($content.version)"
            FunctionsToExport = $functions
            Author =  $($content.authors)
            CompanyName = $($content.owners)
            FileList = $files
            RootModule = "$($this.ModuleName).psm1" 
            Description = 'Microsoft Graph Entra PowerShell.'    
            DotNetFrameworkVersion = $([System.Version]::Parse('4.7.2')) 
            PowerShellVersion = $([System.Version]::Parse('5.1'))
            CompatiblePSEditions = @('Desktop','Core')
            RequiredModules =  $requiredModules
            NestedModules = @()
        }
        
        if($null -ne $content.Prerelease){
            $PSData.Prerelease = $content.Prerelease
        }

        $this.LoadMessage = $this.LoadMessage.Replace("{VERSION}", $content.version)
        New-ModuleManifest @moduleSettings
        Update-ModuleManifest -Path $manisfestPath -PrivateData $PSData
    }

    # Creates the ModuleMap object, this is mainly used by other methods but can be called when debugging or finding missing cmdlets
    hidden [MappedCmdCollection] Map(){

        Write-Host($this.NewPrefix)

        $this.ModuleMap = [MappedCmdCollection]::new($this.ModuleName)
        $originalCmdlets = $this.GetModuleCommands($this.SourceModuleName, $this.SourceModulePrefixs, $true)
        $targetCmdlets = $this.GetModuleCommands($this.DestinationModuleName, $this.DestinationPrefixs, $true)

        $newCmdletData = @()
        $cmdletsToExport = @()
        $missingCmdletsToExport = @()
        if('Microsoft.Graph.Entra' -eq $this.ModuleName){
            $cmdletsToSkip = @("Add-AzureADMSApplicationOwner", "Get-AzureADMSApplication", "Get-AzureADMSApplicationExtensionProperty", "Get-AzureADMSApplicationOwner", "New-AzureADApplication", "New-AzureADMSApplicationExtensionProperty", "Remove-AzureADMSApplication", "Remove-AzureADMSApplicationExtensionProperty", "Remove-AzureADMSApplicationOwner", "Set-AzureADApplication", "Set-AzureADMSApplicationLogo", "Get-AzureADMSGroup", "New-AzureADGroup", "Remove-AzureADMSGroup", "Set-AzureADGroup")        
        }
        else{
            $cmdletsToSkip = @("Add-AzureADMSAdministrativeUnitMember", "Add-AzureADMSScopedRoleMembership", "Get-AzureADMSAdministrativeUnit", "Get-AzureADMSAdministrativeUnitMember", "Get-AzureADMSScopedRoleMembership", "New-AzureADAdministrativeUnit", "Remove-AzureADMSAdministrativeUnit", "Remove-AzureADMSAdministrativeUnitMember", "Remove-AzureADMSScopedRoleMembership", "Set-AzureADAdministrativeUnit", "Add-AzureADMSApplicationOwner", "Get-AzureADMSApplication", "Get-AzureADMSApplicationExtensionProperty", "Get-AzureADMSApplicationOwner", "New-AzureADApplication","New-AzureADMSApplicationExtensionProperty","Remove-AzureADMSApplication","Remove-AzureADMSApplicationExtensionProperty","Remove-AzureADMSApplicationOwner","Set-AzureADApplication","Set-AzureADMSApplicationLogo","Get-AzureADMSGroup","New-AzureADGroup","Remove-AzureADMSGroup","Set-AzureADGroup","Get-AzureADMSPrivilegedRoleAssignment","Get-AzureADMSServicePrincipal","Set-AzureADMSServicePrincipal","Get-AzureADMSUser","Set-AzureADMSUser","New-AzureADMSUser","New-AzureADMSServicePrincipal")
        }
        foreach ($cmd in $originalCmdlets.Keys){
            if ($cmdletsToSkip -contains $cmd) {
                continue
            }
            $originalCmdlet = $originalCmdlets[$cmd]
            $newFunction = $this.GetNewCmdTranslation($cmd, $originalCmdlet, $targetCmdlets, $this.NewPrefix)
            if($newFunction){
                $newCmdletData += $newFunction
                $cmdletsToExport += $newFunction.Generate                    
            }
            else{  
                $missingCmdletsToExport += $cmd                          
                $this.MissingCommandsToMap += $cmd
            } 
        }

        $missingCmdFromURLMapping = $this.GetNewCmdFromURLMapping($newCmdletData,$this.NewPrefix)

        # foreach($function in $missingCmdFromURLMapping){
        #     $this.missingCmdFromURLMap.Add( $function)
        #     $cmdletsToExport += $function.Generate
        # }

        foreach($function in $missingCmdFromURLMapping){
            $newCmdletData+=$function
            $cmdletsToExport += $function.Generate
        }

        foreach($function in $this.HelperCmdletsToExport.GetEnumerator()){
            $cmdletsToExport += $function.Key
        }
        $this.GetNewCmdFromURLMapping($newCmdletData,$this.NewPrefix)
        $this.ModuleMap.CommandsList = $cmdletsToExport
        $this.ModuleMap.MissingCommandsList = $missingCmdletsToExport
        $this.ModuleMap.Commands = $this.NewModuleMap($newCmdletData)

        return $this.ModuleMap
    }    

    hidden [array] GetNewCmdFromURLMapping([array] $newCmdletData, $prefix){
        $missingCMdFromULRMapping = @()

        foreach ($item in $this.ModuleUrlsMapping) {
            if (-not $newCmdletData.Old.Contains($item.Command)) {
               $cmdDetails= $this.GetParsedCmd($item.Command,$prefix)

                $cmd = [PSCustomObject]@{
                    Old = $item.Command
                    New = $item.Command
                    Generate = '{0}-{1}{2}' -f $cmdDetails.Verb, $Prefix, $cmdDetails.Noun
                    Noun = $cmdDetails.Noun
                    Verb = $cmdDetails.Verb
                    Parameters = $null
                    DefaultParameterSet = ""
                    CustomScript = $null
                    type="new"
                }

            $missingCMdFromULRMapping +=$cmd
            }
        }

        return $missingCMdFromULRMapping
    }
    

    hidden [scriptblock] GetUnsupportedCommand(){
        $unsupported = @"
function Get-EntraUnsupportedCommand {
    Throw [System.NotSupportedException] "This commands is currently not supported by the Microsoft Graph Entra PowerShell."
}

"@

        return [scriptblock]::Create($unsupported)
    }

    hidden [scriptblock] GetAlisesFunction() {
        if($this.ModuleMap){
            $aliases = ''
            foreach ($func in $this.ModuleMap.Commands) {       
                $aliases += "   Set-Alias -Name $($func.SourceName) -Value $($func.Name) -Scope Global -Force`n"
            }
            foreach ($func in $this.MissingCommandsToMap) {
                $aliases += "   Set-Alias -Name $($func) -Value Get-EntraUnsupportedCommand -Scope Global -Force`n"
            }
            #Adding direct aliases for Connect-Entra and Disconnect-Entra
            $aliases += "   Set-Alias -Name Connect-AzureAD -Value Connect-Entra -Scope Global -Force`n"
            $aliases += "   Set-Alias -Name Disconnect-AzureAD -Value Disconnect-Entra -Scope Global -Force`n"
    $aliasFunction = @"
function Enable-EntraAzureADAlias {
$($aliases)}

"@
            return [Scriptblock]::Create($aliasFunction)
        }

        return $null
    }

    hidden [scriptblock] GetExportMemeber() {
        $CommandsToExport = $this.ModuleMap.CommandsList
        $CommandsToExport += "Get-EntraUnsupportedCommand"
        $CommandsToExport += "Enable-EntraAzureADAlias"
        $functionsToExport = @"

Export-ModuleMember -Function @(
    '$($CommandsToExport -Join "','")'
)

"@
        return [Scriptblock]::Create($functionsToExport)
    }

    hidden [scriptblock] SetMissingCommands() {
        $missingCommands = @"
Set-Variable -name MISSING_CMDS -value @('$($this.ModuleMap.MissingCommandsList -Join "','")') -Scope Script -Option ReadOnly -Force

"@
        return [Scriptblock]::Create($missingCommands)
    }

    hidden [CommandTranslation[]] NewModuleMap([PSCustomObject[]] $Commands) {
        [CommandTranslation[]] $translations = @()
        
        foreach($Command in $Commands){
            Write-Host("old $($Command.Old)")  
            if ($Command.type -eq "new" ) {
                $URLMapping = $this.ModuleUrlsMapping | Where-Object { $_.command -eq $Command.Old }
                $translations += $this.NewFunctionURLMap($Command, $URLMapping)
            }
            elseif($this.ModuleUrlsMapping | Where-Object { $_.Command -eq $Command.Old }) {
                $URLMapping = $this.ModuleUrlsMapping | Where-Object { $_.command -eq $Command.Old }
                $translations += $this.NewFunctionURLMap($Command, $URLMapping)
            }
            elseif('' -eq $command.New){
                $translations += $this.NewCustomFunctionMap($Command)
            }
            else {
                $translations += $this.NewFunctionMap($Command)
            }            
        }
        return $translations
    }

    hidden [CommandTranslation] NewCustomFunctionMap([PSCustomObject] $Command){
        Write-Host "Creating custom function map for $($Command.Generate)"
        $parameterDefinitions = $this.GetParametersDefinitions($Command)
        $ParamterTransformations = $this.GetParametersTransformations($Command)
        $OutputTransformations = $this.GetOutputTransformations($Command)
        $function = @"
function $($Command.Generate) {
    [CmdletBinding($($Command.DefaultParameterSet))]
    param (
$parameterDefinitions
    )

$($Command.CustomScript)    
}

"@
        $codeBlock = [Scriptblock]::Create($function)
        return [CommandTranslation]::New($Command.Generate,$Command.Old,$codeBlock)
    }

    hidden [CommandTranslation] NewFunctionURLMap([PSCustomObject] $Command, [CommandUrlMap] $URLMapping ){
        Write-Host "Creating new function for $($Command.Generate) with graph URL"
        $parameterDefinitions ="";
        $ParamterTransformations="";
        if($Command.type -eq "new"){
            $parameterDefinitions =$this.GetParametersDefinitionsForNewURLCmd($URLMapping)
            write-host("parameterDefinitions  " +$parameterDefinitions)

            $ParamterTransformations = $this.GetParametersTransformationsFromUrlMappingNewURL($URLMapping)
            write-host("ParamterTransformations  " +$ParamterTransformations)
        }else {
            $parameterDefinitions = $this.GetParametersDefinitionsForNewURLCmd($URLMapping)
            $ParamterTransformations = $this.GetParametersTransformationsFromUrlMappingNewURL($URLMapping)
            #$ParamterTransformations = $this.GetParametersTransformationsFromUrlMapping($Command,$URLMapping)
        }

        #$ParamterTransformations = $this.GetParametersTransformations($Command)
        $OutputTransformations = $this.GetOutputTransformations($Command)
        $keyId=''
        if($Command.type -ne "new"){
            $keyId = $this.GetKeyIdPair($Command)
        }
        $customHeadersCommandName = "New-EntraCustomHeaders"
        $URLCommand = $this.GetURLCommand($URLMapping)


        if($this.ModuleName -eq 'Microsoft.Graph.Entra.Beta')
        {
            $customHeadersCommandName = "New-EntraBetaCustomHeaders"
        }

       

        $function = @"
function $($Command.Generate) {
    [CmdletBinding($($Command.DefaultParameterSet))]
    param (
$parameterDefinitions
    )

    PROCESS {    
    `$params = @{}
    `$customHeaders = $customHeadersCommandName -Command `$MyInvocation.MyCommand
    $($keyId)    
    `$URL = '$($URLMapping.URL)'
    $($this.GetRplacedURLByParametersNewURL($URLMapping))
$ParamterTransformations
    Write-Debug("============================ TRANSFORMATIONS ============================")
    `$params.Keys | ForEach-Object {"`$_ : `$(`$params[`$_])" } | Write-Debug
    Write-Debug("=========================================================================``n")
    
    `$response = $($URLCommand) -Headers `$customHeaders
    try{
    `$response = `$response.value | ConvertTo-Json -Depth 10 | ConvertFrom-Json

    }
catch{
    `$response = `$response | ConvertTo-Json -Depth 10 | ConvertFrom-Json
}
$OutputTransformations
    `$response
    }
}

"@
        
        write-host($function)
        $codeBlock = [Scriptblock]::Create($function)
        return [CommandTranslation]::New($Command.Generate,$Command.Old,$codeBlock)
    }

    

    hidden [string] GetURLCommand([CommandUrlMap] $URLMapping){
        switch ($URLMapping.Method) {
            "POST" { return " Invoke-GraphRequest -Uri `$URL -Method  $($URLMapping.Method) -body `$params"}  
            "GET" { return " Invoke-GraphRequest -Uri (`$URL + `$query) -Method  $($URLMapping.Method)"}            
        }

        return ""
    }

    
    hidden [CommandTranslation] NewFunctionMap([PSCustomObject] $Command){
        Write-Host "Creating new function for $($Command.Generate)"
        $parameterDefinitions = $this.GetParametersDefinitions($Command)
        $ParamterTransformations = $this.GetParametersTransformations($Command)
        $OutputTransformations = $this.GetOutputTransformations($Command)
        $keyId = $this.GetKeyIdPair($Command)
        $customHeadersCommandName = "New-EntraCustomHeaders"

        if($this.ModuleName -eq 'Microsoft.Graph.Entra.Beta')
        {
            $customHeadersCommandName = "New-EntraBetaCustomHeaders"
        }

        $function = @"
function $($Command.Generate) {
    [CmdletBinding($($Command.DefaultParameterSet))]
    param (
$parameterDefinitions
    )

    PROCESS {    
    `$params = @{}
    `$customHeaders = $customHeadersCommandName -Command `$MyInvocation.MyCommand
    $($keyId)
$ParamterTransformations
    Write-Debug("============================ TRANSFORMATIONS ============================")
    `$params.Keys | ForEach-Object {"`$_ : `$(`$params[`$_])" } | Write-Debug
    Write-Debug("=========================================================================``n")
    
    `$response = $($Command.New) @params -Headers `$customHeaders    
$OutputTransformations
    `$response
    }
}

"@
        $codeBlock = [Scriptblock]::Create($function)
        return [CommandTranslation]::New($Command.Generate,$Command.Old,$codeBlock)
    }

    hidden [string] GetParametersDefinitionsForNewURLCmd([PSCustomObject] $Command) {
        $commonParameterNames = @("ProgressAction","Verbose", "Debug","ErrorAction", "ErrorVariable", "WarningAction", "WarningVariable", "OutBuffer", "PipelineVariable", "OutVariable", "InformationAction", "InformationVariable","WhatIf","Confirm")          
        
        $paramsList = @()
        foreach ($param in $Command.Parameters) {
            if($commonParameterNames.Contains($param.Name)) {
                continue
            }
            $paramBlock = @"
    $($this.GetParameterAttributesNeweURL($Param))[$($param.DataType)] `$$($param.Name)
"@
            $paramsList += $paramBlock
        }
        
        return $paramsList -Join ",`n"
    }


    hidden [string] GetParametersDefinitions([PSCustomObject] $Command) {
        $commonParameterNames = @("ProgressAction","Verbose", "Debug","ErrorAction", "ErrorVariable", "WarningAction", "WarningVariable", "OutBuffer", "PipelineVariable", "OutVariable", "InformationAction", "InformationVariable","WhatIf","Confirm")  
        $ignorePropertyParameter = @("Get-EntraBetaApplicationPolicy", "Get-EntraBetaApplicationSignInSummary","Get-EntraBetaMSPrivilegedRoleAssignment","Get-EntraBetaMSTrustFrameworkPolicy","Get-EntraBetaPolicy","Get-EntraBetaPolicyAppliedObject","Get-EntraBetaServicePrincipalPolicy","Get-EntraApplicationLogo","Get-EntraBetaApplicationLogo","Get-EntraApplicationKeyCredential","Get-EntraBetaApplicationKeyCredential","Get-EntraBetaServicePrincipalKeyCredential","Get-EntraBetaServicePrincipalPasswordCredential","Get-EntraServicePrincipalKeyCredential","Get-EntraServicePrincipalPasswordCredential")
        $params = $(Get-Command -Name $Command.Old).Parameters
        $paramsList = @()
        foreach ($paramKey in $Command.Parameters.Keys) {
            if($commonParameterNames.Contains($paramKey)) {
                continue
            }
            $param = $params[$paramKey]
            $paramType = $param.ParameterType.ToString()
            $paramtypeToCreate = $param.ParameterType.ToString()
            if($param.Name -eq 'All'){
                $paramType = "switch"
            }
            if(($null -ne $this.TypePrefix) -and ($paramType -like "*$($this.TypePrefix)*")){
                if($paramType -like "*List*"){
                    $paramType = "System.Collections.Generic.List``1[$($param.ParameterType.GenericTypeArguments.FullName)]"
                    $paramtypeToCreate = $param.ParameterType.GenericTypeArguments.FullName
                }
                elseif($paramType -like "*Nullable*"){
                    $paramType = "System.Nullable``1[$($param.ParameterType.GenericTypeArguments.FullName)]"
                    $paramtypeToCreate = $param.ParameterType.GenericTypeArguments.FullName
                }
                if(!$this.TypesToCreate.Contains($paramtypeToCreate)) {
                    $this.TypesToCreate += $paramtypeToCreate
                }                
            }           
            $paramBlock = @"
    $($this.GetParameterAttributes($Param))[$($paramType)] `$$($param.Name)
"@
            $paramsList += $paramBlock
        }

        if("Get" -eq $Command.Verb -and !$ignorePropertyParameter.Contains($Command.Generate)){
            $paramsList += $this.GetPropertyParameterBlock()
        }

        return $paramsList -Join ",`n"
    }

    hidden [string] GetPropertyParameterBlock(){
        $propertyType = "System.String[]"
        $arrayAttrib = @()
        $arrayAttrib += "Mandatory = `$false"
        $arrayAttrib += "ValueFromPipeline = `$false"
        $arrayAttrib += "ValueFromPipelineByPropertyName = `$true"
        $strAttrib = $arrayAttrib -Join ', '
        $attributesString += "[Parameter($strAttrib)]`n    "
        $propertyParamBlock = @"
    $attributesString[$propertyType] `$Property
"@
        return $propertyParamBlock
    }

    hidden [string] GetParameterAttributesNeweURL($param){
        $attributesString = ""

        
            $arrayAttrib = @()
            
            try {
                if($param.ParameterSetName -ne "__AllParameterSets"){
                    $arrayAttrib += "ParameterSetName = `"$($param.ParameterSetName)`""
                }
            }
            catch {}                
            
           try {
                if($param.Mandatory){
                    $arrayAttrib += "Mandatory = `$true"
                }
           }
           catch {}
                
           
           try {
                if($param.ValueFromPipeline){
                    $arrayAttrib += "ValueFromPipeline = `$true"
                }
           }
           catch {}
                
            try {
                if($param.ValueFromPipelineByPropertyName){
                    $arrayAttrib += "ValueFromPipelineByPropertyName = `$true"
                }
            }
            catch {}
           
            $strAttrib = $arrayAttrib -Join ', '

            if($strAttrib.Length -gt 0){
                $attributesString += "[Parameter($strAttrib)]`n    "
            }
        

        return $attributesString
    }

    hidden [string] GetParameterAttributes($param){
        $attributesString = ""

        foreach($attrib in $param.Attributes){
            $arrayAttrib = @()
            
            try {
                if($attrib.ParameterSetName -ne "__AllParameterSets"){
                    $arrayAttrib += "ParameterSetName = `"$($attrib.ParameterSetName)`""
                }
            }
            catch {}                
            
           try {
                if($attrib.Mandatory){
                    $arrayAttrib += "Mandatory = `$true"
                }
           }
           catch {}
                
           
           try {
                if($attrib.ValueFromPipeline){
                    $arrayAttrib += "ValueFromPipeline = `$true"
                }
           }
           catch {}
                
            try {
                if($attrib.ValueFromPipelineByPropertyName){
                    $arrayAttrib += "ValueFromPipelineByPropertyName = `$true"
                }
            }
            catch {}
           
            $strAttrib = $arrayAttrib -Join ', '

            if($strAttrib.Length -gt 0){
                $attributesString += "[Parameter($strAttrib)]`n    "
            }
        }

        return $attributesString
    }

    hidden [string] GetRplacedURLByParametersNewURL([CommandUrlMap] $URLMapping) {
        $paramsBlock=''
        foreach ($param in $URLMapping.Parameters){
            if($param.IsURLReplaced -eq $True){
                $paramsBlock += @"
    if(`$null -ne `$URL)
    {
        `$URL = `$URL.Replace("{$($param.Name)}",`$PSBoundParameters["$($param.Name)"])
        
    }

"@
            }
           
        }

        return $paramsBlock
    }

    hidden [string] GetParametersTransformationsFromUrlMappingNewURL([CommandUrlMap] $URLMapping) {
       
       Write-Host("metod " + $URLMapping.Method)
        $paramsList = ""
       switch ($URLMapping.Method) {
            "POST" { 
                foreach ($param in $URLMapping.Parameters){
                        $paramsList += $this.GetCustomParameterTransformation($param.Name)
                    }
                }
                  
            "GET" { 
                $paramsList += "`$query = ''
                                `$idQuery =''

                "                
                
                foreach ($param in $URLMapping.Parameters){
                    switch ($param.Name) {
                        "Top" { 
                            $paramsList += $this.GetTopParameterTransformation() 
                            break
                        }
                        "Id" {
                            #$paramsList += $this.GetIdParameterTransformation() 
                            $paramsList += $this.GetCustomParameterTransformation($param.Name)
                            break
                        }
                        "Filter" {
                            $paramsList += $this.GetFilterParameterTransformation() 
                            break
                        }
                        Default {
                            $paramsList += $this.GetCustomParameterTransformation($param.Name)
                            break
                        }
                    }                
                }

#                 $paramsList += @"
#     if(`$null -ne `$query)
#     {
#         `$query = "?" + `$query.TrimStart("&")
#         `$query = `$idQuery + `$query
#         `$query = `$query.TrimEnd("?")
#     }

# "@

$paramsList += @"
    if(`$null -ne `$query)
    {
        `$query = "?" + `$query.TrimStart("&")
        #`$query = `$idQuery + `$query
        #`$query = `$query.TrimEnd("?")
    }

"@
            }            
        }

        
        return $paramsList
    }
    
    

    hidden [string] GetParametersTransformationsFromUrlMapping([PSCustomObject] $Command,[CommandUrlMap] $URLMapping) {
        $paramsList = ""
        $URLMapping = $this.ModuleUrlsMapping | Where-Object { $_.command -eq $Command.Old }

        foreach ($paramKey in $Command.Parameters.Keys) {        
            $param = $Command.Parameters[$paramKey]
            $paramBlock = ""
            if($URLMapping.Parameters.Count -gt 0)
            {
                # Find the matching parameter in the URLMapping.Parameters array
                $matchingParam = $URLMapping.Parameters | Where-Object { $_.Name -eq $param.Name }
                
                Write-Host("matching param $($matchingParam)")
                
                if($matchingParam)
                {
                    if([TransformationTypes]::Name -eq $matchingParam.ConversionType){
                        $paramBlock = $this.GetParameterTransformationName($matchingParam.Name, $matchingParam.TargetName)
                    }
                    elseif([TransformationTypes]::Bool2Switch -eq $matchingParam.ConversionType){
                        $paramBlock = $this.GetParameterTransformationBoolean2Switch($matchingParam.Name, $matchingParam.TargetName)
                    }
                    elseif([TransformationTypes]::SystemSwitch -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterTransformationSystemSwitch($matchingParam.Name)
                    }
                    elseif([TransformationTypes]::ScriptBlock -eq $matchingParam.ConversionType){
                        $paramBlock = $this.GetParameterCustom($matchingParam)
                    }
                    elseif([TransformationTypes]::Remove -eq $matchingParam.ConversionType){
                        $paramBlock = $this.GetParameterException($matchingParam)
                    }
                }
                else{
                    if([TransformationTypes]::None -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterTransformationName($param.Name, $param.Name)
                    }
                    elseif([TransformationTypes]::Name -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterTransformationName($param.Name, $param.TargetName)
                    }
                    elseif([TransformationTypes]::Bool2Switch -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterTransformationBoolean2Switch($param.Name, $param.TargetName)
                    }
                    elseif([TransformationTypes]::SystemSwitch -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterTransformationSystemSwitch($param.Name)
                    }
                    elseif([TransformationTypes]::ScriptBlock -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterCustom($param)
                    }
                    elseif([TransformationTypes]::Remove -eq $param.ConversionType){
                        $paramBlock = $this.GetParameterException($param)
                    }
                }

            }else {
                
                if([TransformationTypes]::None -eq $param.ConversionType){
                    $paramBlock = $this.GetParameterTransformationName($param.Name, $param.Name)
                }
                elseif([TransformationTypes]::Name -eq $param.ConversionType){
                    $paramBlock = $this.GetParameterTransformationName($param.Name, $param.TargetName)
                }
                elseif([TransformationTypes]::Bool2Switch -eq $param.ConversionType){
                    $paramBlock = $this.GetParameterTransformationBoolean2Switch($param.Name, $param.TargetName)
                }
                elseif([TransformationTypes]::SystemSwitch -eq $param.ConversionType){
                    $paramBlock = $this.GetParameterTransformationSystemSwitch($param.Name)
                }
                elseif([TransformationTypes]::ScriptBlock -eq $param.ConversionType){
                    $paramBlock = $this.GetParameterCustom($param)
                }
                elseif([TransformationTypes]::Remove -eq $param.ConversionType){
                    $paramBlock = $this.GetParameterException($param)
                }
                
            }
            
            $paramsList += $paramBlock            
        }

        if("Get" -eq $Command.Verb){
            $paramsList += $this.GetCustomParameterTransformation("Property")
        }
            
        return $paramsList
    }

    hidden [string] GetParametersTransformations([PSCustomObject] $Command) {
        $paramsList = ""

        foreach ($paramKey in $Command.Parameters.Keys) {        
            $param = $Command.Parameters[$paramKey]
            $paramBlock = ""
            
            if([TransformationTypes]::None -eq $param.ConversionType){
                $paramBlock = $this.GetParameterTransformationName($param.Name, $param.Name)
            }
            elseif([TransformationTypes]::Name -eq $param.ConversionType){
                $paramBlock = $this.GetParameterTransformationName($param.Name, $param.TargetName)
            }
            elseif([TransformationTypes]::Bool2Switch -eq $param.ConversionType){
                $paramBlock = $this.GetParameterTransformationBoolean2Switch($param.Name, $param.TargetName)
            }
            elseif([TransformationTypes]::SystemSwitch -eq $param.ConversionType){
                $paramBlock = $this.GetParameterTransformationSystemSwitch($param.Name)
            }
            elseif([TransformationTypes]::ScriptBlock -eq $param.ConversionType){
                $paramBlock = $this.GetParameterCustom($param)
            }
            elseif([TransformationTypes]::Remove -eq $param.ConversionType){
                $paramBlock = $this.GetParameterException($param)
            }
            
            $paramsList += $paramBlock            
        }

        if("Get" -eq $Command.Verb){
            $paramsList += $this.GetCustomParameterTransformation("Property")
        }
            
        return $paramsList
    }

    hidden [string] GetKeyIdPair($Command){        
        $keys = @()
        foreach ($paramKey in $Command.Parameters.Keys) {        
            $param = $Command.Parameters[$paramKey]
            if($param.NameChanged){
                if($param.Name -eq "ObjectId"){
                    $keys += "$($param.Name) = `"Id`""
                }
                elseif($param.Name -eq "Id"){
                }
                else{
                    $keys += "$($param.Name) = `"$($param.TargetName)`""
                }
            }            
        }
            
        return "`$keysChanged = @{$($keys -Join "; ")}"
    }

    hidden [string] GetParameterTransformationName([string] $OldName, [string] $NewName){
        $paramBlock = @"
    if(`$null -ne `$PSBoundParameters["$($OldName)"])
    {
        `$params["$($NewName)"] = `$PSBoundParameters["$($OldName)"]
    }

"@
        return $paramBlock
    }

    hidden [string] GetParameterTransformationBoolean2Switch([string] $OldName, [string] $NewName){
        $paramBlock = @"
    if(`$null -ne `$PSBoundParameters["$($OldName)"])
    {
        if(`$PSBoundParameters["$($OldName)"])
        {
            `$params["$($NewName)"] = `$PSBoundParameters["$($OldName)"]
        }
    }

"@
        return $paramBlock
    }

    hidden [string] GetParameterTransformationSystemSwitch([string] $Name){
        $paramBlock = @"
    if(`$PSBoundParameters.ContainsKey("$($Name)"))
    {
        `$params["$($Name)"] = `$Null
    }

"@
        return $paramBlock
    }


    hidden [string] GetParameterException([DataMap] $Param){
        $paramBlock = ""
        return $paramBlock
    }

    hidden [string] GetParameterCustom([DataMap] $Param){
        $paramBlock = @"
    if(`$null -ne `$PSBoundParameters["$($Param.Name)"])
    {
        `$TmpValue = `$PSBoundParameters["$($Param.Name)"]
        $($Param.SpecialMapping)
        `$params["$($Param.TargetName)"] = `$Value
    }

"@
        return $paramBlock
    }

    hidden [string] GetCustomParameterTransformation([string] $ParameterName){
        $paramBlock = @"
    if(`$null -ne `$PSBoundParameters["$($ParameterName)"])
    {
        `$params["$($ParameterName)"] = `$PSBoundParameters["$($ParameterName)"]
    }

"@
        return $paramBlock
    }

    hidden [string] GetTopParameterTransformation (){       
    
        $paramBlock = @"
        if (`$null -ne `$PSBoundParameters["Top"]) 
        {
            `$topCount = `$PSBoundParameters["Top"]
            if (`$topCount -gt 999) {
                `$query += "&top=999"
            } else {
                `$query += "&top=`$topCount"
            }
        }

"@
        return $paramBlock
    }

    hidden [string] GetFilterParameterTransformation() {        
        $paramBlock = @"
        if (`$null -ne `$PSBoundParameters["Filter")"]) 
        {
            `$filter = `$PSBoundParameters["Filter"]
            `$f = '`$filter'
            `$query += "&`f=`$filter"
        }

"@
        return $paramBlock
    }

    hidden [string] GetIdParameterTransformation() {
        
        $paramBlock = @"
        if (`$null -ne `$PSBoundParameters["Id"]) 
        {
            `$logId = `$PSBoundParameters["Id"]
            `$idQuery = `"/`$(`$logId)`"
        }

"@
        return $paramBlock
    }
    
    
    
    hidden [string] GetOutputTransformations([PSCustomObject] $Command) {
        $responseVerbs = @("Get","Add","New")
        $output = ""
    
        if($this.CmdCustomizations.ContainsKey($Command.Old)) { 
            $cmd = $this.CmdCustomizations[$Command.Old] 
            if($null -ne $cmd.Outputs){                   
                foreach($key in $cmd.Outputs.GetEnumerator()) {
                    $customOutput =  $cmd.Outputs[$key.Name]
                    if([TransformationTypes]::Name -eq $customOutput.ConversionType){
                        $output += $this.GetOutputTransformationName($customOutput.Name, $customOutput.TargetName)
                    }
                    elseif([TransformationTypes]::ScriptBlock -eq $customOutput.ConversionType){
                        $output += $this.GetOutputTransformationCustom($customOutput)
                    }
                    elseif([TransformationTypes]::FlatObject -eq $customOutput.ConversionType){
                        $output += $this.GetOutputTransformationFlatObject($customOutput)
                    }
                }
            }
        }
        
        foreach($key in $this.GenericOutputTransformations.GetEnumerator()) {
            $customOutput =  $this.GenericOutputTransformations[$key.Name]
            if(2 -eq $customOutput.ConversionType){
                $output += $this.GetOutputTransformationName($customOutput.Name, $customOutput.TargetName)
            }
            elseif([TransformationTypes]::ScriptBlock -eq $customOutput.ConversionType){
                $output += $this.GetOutputTransformationCustom($customOutput)
            }
            elseif([TransformationTypes]::FlatObject -eq $customOutput.ConversionType){
                $output += $this.GetOutputTransformationFlatObject($customOutput)
            }
        }             
                    
        if("" -ne $output){
            $transform = @"
    `$response | ForEach-Object {
        if(`$null -ne `$_) {
$($output)
        }
    }
"@
            return $transform
        }
        return ""
    }

    hidden [string] GetOutputTransformationName([string] $OldName, [string] $NewName){
        $outputBlock =@"
        Add-Member -InputObject `$_ -MemberType AliasProperty -Name $($NewName) -Value $($OldName)

"@
        return $outputBlock
    }

    hidden [string] GetOutputTransformationCustom([DataMap] $Param){
        $outputBlock =@"
        $($Param.SpecialMapping)
        Add-Member -InputObject `$_ -MemberType ScriptProperty -Name $($Param.TargetName) -Value `$Value

"@
        return $outputBlock
    }

    hidden [string] GetOutputTransformationFlatObject([DataMap] $Param){
        $outputBlock =@"
        Add-Member -InputObject `$_ -NotePropertyMembers `$_.$($Param.Name)

"@
        return $outputBlock
    }

    hidden [hashtable] GetModuleCommands([string[]] $ModuleNames, [string[]] $Prefix, [bool] $IgnoreEmptyNoun = $false){
        
        $names = @()
        foreach ($moduleName in $ModuleNames) {
            $module = Get-Module -Name $moduleName
            $names += $module.ExportedCmdlets.Keys
            $names += $module.ExportedFunctions.Keys
        }
    
        $namesDic = @{}
        foreach ($name in $names) {
            $cmdComponents = $this.GetParsedCmd($name, $Prefix)
            if(!$cmdComponents){
                $this.MissingCommandsToMap += $name
                continue
            }
            if($IgnoreEmptyNoun -and !$cmdComponents.Noun) {
                continue
            }

            $namesDic.Add($name, $cmdComponents)
        }
    
        return $namesDic
    }

    hidden [PSCustomObject] GetParsedCmd([string]$Name, [string[]]$Prefixs){
        foreach ($prefix in $Prefixs) {
            $components = $name -split '-'      
            $verb = $components[0]
            $prefixNoun = $components[1]
            $components = $prefixNoun -split $prefix
            if($components.Length -eq 1)
            {
                continue
            }
            $noun = $prefixNoun.Substring($prefix.Length, $prefixNoun.Length - $prefix.Length)
        
            return [PSCustomObject] @{
                Verb = $verb
                Noun = $noun
                Prefix = $prefix
            }                  
        }
        return $null
    }

    hidden [PSCustomObject] GetNewCmdTranslation($SourceCmdName, $SourceCmdlet, $TargetCmdlets, $NewPrefix){
        $verbsEquivalence = @{
            'Get' = @('Get')
            'New' = @('New','Add')
            'Add' = @('New','Add')
            'Remove' = @('Remove','Delete')
            'Delete' = @('Remove','Delete')
            'Set' = @('Set','Update')
            'Update' = @('Set','Update')
            'Confirm' = @('Confirm')
            'Enable' = @('New')
        }
    
        $targetCmd = $null
        if($this.CmdCustomizations.ContainsKey($SourceCmdName)){
            $targetCmd = $this.CmdCustomizations[$SourceCmdName].TargetName
        }
        else {
            foreach ($prefix in $this.DestinationPrefixs){
                foreach ($verb in $verbsEquivalence[$SourceCmdlet.Verb]){
                    $tmpCmd = "$($verb)-$($prefix)$($SourceCmdlet.Noun)"
                    if($TargetCmdlets.ContainsKey($tmpCmd)){
                        $targetCmd = $tmpCmd;
                        break;
                    }
                }
            }
        }
      
        if($null -ne $targetCmd){
            if($SourceCmdlet.Prefix.contains('MS')){
                $Prefix = $NewPrefix
            } else {
                $prefix = $NewPrefix
            }
            $cmd = [PSCustomObject]@{
                Old = '{0}-{1}{2}' -f $SourceCmdlet.Verb, $SourceCmdlet.Prefix, $SourceCmdlet.Noun
                New = $targetCmd
                Generate = '{0}-{1}{2}' -f $SourceCmdlet.Verb, $Prefix, $SourceCmdlet.Noun
                Noun = $SourceCmdlet.Noun
                Verb = $SourceCmdlet.Verb
                Parameters = $null
                DefaultParameterSet = ""
                CustomScript = $null
                type=""
            }
            if('' -eq $targetCmd){
                $cmd.CustomScript = $this.CmdCustomizations[$SourceCmdName].CustomScript
            }
            $cmd.Parameters = $this.GetCmdletParameters($cmd)
            $defaulParam = $this.GetDefaultParameterSet($SourceCmdName)
            $cmd.DefaultParameterSet = "DefaultParameterSetName = '$defaulParam'"
            return $cmd
        }

        return $null
    }

    hidden [string] GetDefaultParameterSet($Cmdlet){
        $sourceCmd = Get-Command -Name $Cmdlet

        return $sourceCmd.DefaultParameterSet
    }

    hidden [hashtable] GetCmdletParameters($Cmdlet){
        $Bool2Switch = @("All")
        $SystemDebug = @("Verbose", "Debug")
        $commonParameterNames = @("ErrorAction", "ErrorVariable", "WarningAction", "WarningVariable", "OutBuffer", "PipelineVariable", "OutVariable", "InformationAction", "InformationVariable")
        $sourceCmd = Get-Command -Name $Cmdlet.Old
        $targetCmd = $null
        if('' -ne $Cmdlet.New){
            $targetCmd = Get-Command -Name $Cmdlet.New                
        } 

        $paramsList = @{}
        foreach ($paramKey in $sourceCmd.Parameters.Keys) {
            $param = $sourceCmd.Parameters[$paramKey]            
            $paramObj = [DataMap]::New($param.Name)
            
            if($this.CmdCustomizations.ContainsKey($Cmdlet.Old)) {
                $custom = $this.CmdCustomizations[$Cmdlet.Old]
                if(($null -ne $custom.Parameters) -and ($custom.Parameters.contains($param.Name))){
                    Write-Host($custom.Parameters[$param.Name])
                    $paramsList.Add($param.Name, $custom.Parameters[$param.Name])
                    continue
                }
                if($custom.SpecialMapping) {
                    $paramObj.SetNone() 
                    $paramsList.Add($param.Name, $paramObj)
                    continue
                }
            }
            
            if($this.GenericParametersTransformations.ContainsKey($param.Name)) {
                $genericParam = $this.GenericParametersTransformations[$param.Name]
                if(5 -eq $genericParam.ConversionType){
                    $tempName = "$($Cmdlet.Noun)$($genericParam.TargetName)"
                    if($targetCmd.Parameters.ContainsKey($tempName)){
                        $paramObj.SetTargetName($tempName)
                    }
                    elseif($targetCmd.Parameters.ContainsKey($genericParam.TargetName)){                       
                        $paramObj.SetTargetName($genericParam.TargetName)
                    }
                    else
                    {
                        foreach ($key in $targetCmd.Parameters.Keys) {
                            if($key.EndsWith($genericParam.TargetName)){
                                $paramObj.SetTargetName($key)
                                break
                            }
                        }
                    }
                    $paramsList.Add($paramObj.Name,$paramObj)                    
                }else{
                    $paramsList.Add($genericParam.Name, $genericParam)
                }   
                continue
            }
            
            if($commonParameterNames.Contains($param.Name)) {
                $paramObj.SetNone()
            }
            elseif($Bool2Switch.Contains($param.Name)) {
                $paramObj.SetBool2Switch($param.Name)
            }
            elseif($SystemDebug.Contains($param.Name)) {
                $paramObj.SetSystemSwitch($param.Name)
            }
            else
            {
                if($targetCmd.Parameters.ContainsKey($param.Name)){
                    $paramObj.SetNone()                       
                }
            }
        
            $paramsList.Add($paramObj.Name,$paramObj)
        }
    
        return $paramsList        
    }

    hidden [string] GetFileHeader(){
        return @"
# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------
Set-StrictMode -Version 5

"@
    }
}
