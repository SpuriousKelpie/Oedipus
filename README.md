# Oedipus
An automated PowerShell tool for identifying potential access control misconfigurations between objects in an Active Directory environment.

Oedipus was written to determine if it was possible to programmatically find users who have unwarranted access to network resources. The idea came from tickets I had encountered working in first line support.

Written in PowerShell 3.0 and tested on Windows Server 2012.

# Usage

```
Controller.ps1 -Identity (Get-Content .\groups.txt) -Scope [Department|Title]
```
