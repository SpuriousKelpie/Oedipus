# Oedipus
A PowerShell tool for finding Active Directory users with unauthorised group memberships.

An Active Directory user can be a member of a security group that gives them access to a shared network resource (files, printers, etc.). It is possible for users to accidentally be given access to a shared resource. This can be a security risk.

This tool attempts to find those users by grouping members of a particular security group together based on a shared attribute (specified using the -Scope parameter). It then determines which of those groups belong to the majority by finding the interquartile range. Users outwith the majority are found using a modified version of the Tukey rule, and then flagged as outliers. A HTML report is then generated that lists those users. An example is shown below.

![output](https://github.com/SpuriousKelpie/Oedipus/blob/master/output.png)

A limitation of the tool is its tendency to report false positives. It therefore does not take any action in response to its findings. The user must determine the appropriate course of action based on the findings presented in the report.

## Prerequisites
The execution policy for your PowerShell session must allow the script to run with administrative privileges. Edit the absolute path to the Oedipus module in the controller script.

## Usage
```
controller.ps1 -Identity (Get-Content .\groups.txt) -Scope <user attribute>
```

## Contribute
If you would like to contribute to the project, then please contact me.

## License
Oedipus is licensed under the GNU General Public License v3.0.
