function Get-DbaClusterSqlInstance
{
<#
.SYNOPSIS
Returns the uptime of the SQL Server instance, and if required the hosting windows server
	
.DESCRIPTION
By default, this command returns for each SQL Server instance passed in:
SQL Instance last startup time, Uptime as a PS TimeSpan, Uptime as a formatted string
Hosting Windows server last startup time, Uptime as a PS TimeSpan, Uptime as a formatted string
	
.PARAMETER Cluster
The SQL Server that you're connecting to.

.PARAMETER ClusterCredential
Credential object used to connect to the SQL Server as a different user

.PARAMETER WindowsCredential
Credential object used to connect to the SQL Server as a different user


.NOTES 
Original Author: Stuart Moore (@napalmgram), stuart-moore.com
	
dbatools PowerShell module (https://dbatools.io, clemaire@gmail.com)
Copyright (C) 2016 Chrissy LeMaire
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>

.LINK
https://dbatools.io/Get-DbaClusterSqlInstances

.EXAMPLE
Get-DbaClusterSqlInstances -ClusterName MyProdCluster.contoso.com

Returns a list of all SQL Server instances that have been setup on the cluster MyProdCluster.contoso.com
.EXAMPLE
$ClusterCredential = Get-Credential
"MyProdCluster.contoso.com","MyTestCluster.contoso.com" | Get-DbaClusterSqlInstances -ClusterCredentual $ClusterCredential | Get-DbaUptime

Connects to the clusters MyProdCluster.contoso.com and MyProdCluster.contoso.com using the specified cluster administrator credentials, 
and then pushes the instance names through to Get-DbaUptime 	
	
#>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	Param (
		[parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string[]]$ClusterName,
		[PsCredential]$ClusterCredential
	)
	BEGIN
	{
		$FunctionName = "Get-DbaClusterSqlInstance"
	}
    PROCESS
    {
        ForEach ($cluster in $ClusterName)
        {
            				try
				{
					Write-Verbose "$FunctinName - Getting Clustered Instances via CimInstance for $Cluster"
					$Results = Get-CimInstance -class "MSCluster_Resource" -namespace "root\mscluster" -computername $Cluster | where {$_.type -eq "SQL Server"}  					
				}
				catch
				{
					try
					{
						Write-Verbose "$functionname - Clustered Instances via CimInstance DCOM for $Cluster"
						$CimOption = New-CimSessionOption -Protocol DCOM
						$CimSession = New-CimSession -Credential:$ClusterCredential -ComputerName $Cluster -SessionOption $CimOption
						$Results = $CimSession | Get-CimInstance -class "MSCluster_Resource" -namespace "root\mscluster"| where {$_.type -eq "SQL Server"}  					
					}
					catch
					{
						Write-Exception $_
					}
				}
				$results | %{ $_.PrivateProperties.VirtualServerName+"\"+$_.PrivateProperties.InstanceName}
        }
    }

}