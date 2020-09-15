# Oedipus
A PowerShell tool for identifying Active Directory users with unauthorised group memberships.

## Usage

```
Controller.ps1 -Identity (Get-Content .\groups.txt) -Scope [Department|Title]
```

## Output

![output](https://github.com/SpuriousKelpie/Oedipus/blob/master/output.png)
