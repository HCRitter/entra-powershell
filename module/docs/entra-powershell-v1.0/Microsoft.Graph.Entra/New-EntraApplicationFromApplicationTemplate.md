---
title: New-EntraApplicationFromApplicationTemplate
description: This article provides details on the New-EntraApplicationFromApplicationTemplate command.


ms.service: entra
ms.topic: reference
ms.date: 07/10/2024
ms.author: eunicewaweru
ms.reviewer: stevemutungi
manager: CelesteDG
author: msewaweru

external help file: Microsoft.Graph.Entra-Help.xml
Module Name: Microsoft.Graph.Entra
online version: https://learn.microsoft.com/powershell/module/Microsoft.Graph.Entra/New-EntraApplicationFromApplicationTemplate
schema: 2.0.0
---

# New-EntraApplicationFromApplicationTemplate

## Synopsis

Instantiates an application.

## Syntax

```powershell
New-EntraApplicationFromApplicationTemplate 
 -Id <String> 
 -DisplayName <ApplicationTemplateDisplayName>
 [<CommonParameters>]
```

## Description

This `New-EntraApplicationFromApplicationTemplate` cmdlet allows users to create application from application template.

## Examples

### Example 1: Creates an application from application template

```powershell
Connect-Entra -Scopes 'Application.ReadWrite.All'
$params = @{
    Id = 'aaaaaaaa-0000-1111-2222-bbbbbbbbbbbb'
    DisplayName = 'ApplicationTemplate'
}
New-EntraApplicationFromApplicationTemplate @params
```

```Output
@odata.context                                                                         servicePrincipal
--------------                                                                         ----------------
https://graph.microsoft.com/v1.0/$metadata#microsoft.graph.applicationServicePrincipal @{oauth2PermissionScopes=System.Object[]; servicePrincipalType=Application; displ...}
```

This command instantiates a new application based on application template referenced by the ID.

- `-Id` Parameter specifies Application TemplateId.
- `-DisplayName` Parameter specifies application template display name.

## Parameters

### -Id

The unique identifier of an object in Microsoft Entra ID.

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -DisplayName

Application template display name.

```yaml
Type: System.ApplicationTemplateDisplayName
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`, `-InformationVariable`, `-OutVariable`, `-OutBuffer`, `-PipelineVariable`, `-Verbose`, `-WarningAction`, and `-WarningVariable`. For more information, see [about_CommonParameters](https://go.microsoft.com/fwlink/?LinkID=113216).

## Inputs

## Outputs

### Microsoft.Online.Administration.ApplicationTemplateCopy

## Notes

## Related Links
