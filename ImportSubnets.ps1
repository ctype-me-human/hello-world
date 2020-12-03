#region COMMENTS
<#
        .SYNOPSIS
            ##
        .DESCRIPTION
            	• requires CSV of subnets to be imported
	            • expected columns: date,division,facility type,pc counts,city,state,zip code,address,region,wired subnet,wired mask,wireless subnet,wireless mask
	            •           
        .PARAMETER ##
        .PARAMETER ##
        .INPUTS
            ##
        .OUTPUTS
            ##
        .EXAMPLE
            ##
        .EXAMPLE
            ##
        .NOTES
            Author:             Erik Kovacs
            Company:            Ashland Inc.
            Date:               2016/07/05
            
            Version:            2016.07.05
            Changelog:
                2016.07.05      Initial Release
        .LINK            
#>
#endregion

#region FUNCTIONS
    function get-ScriptDir {
        #gets directory path this script is run from
        #returns directory script is run from
        #
        return (split-path ($MyInvocation.scriptname))
    }

    function get-inputCSV {
        # Variable initialization
        PARAM([string]$inputFile = "input0.csv")

        # Test for existence of input file
        if (Test-Path "$(get-scriptDir)\$inputFile") {
            # read input file to variable
            $inputObj = Import-Csv "$(get-scriptDir)\$inputFile"       
            
        }
        
        return $inputObj
    }

    function ConvertTo-MaskLength {
          <#
            .Synopsis
              Returns the length of a subnet mask.
            .Description
              ConvertTo-MaskLength accepts any IPv4 address as input, however the output value 
              only makes sense when using a subnet mask.
            .Parameter SubnetMask
              A subnet mask to convert into length
          #>
 
          [CmdLetBinding()]
          param(
            [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
            [Alias("Mask")]
            [Net.IPAddress]$SubnetMask
          )
 
          process {
            $Bits = "$( $SubnetMask.GetAddressBytes() | ForEach-Object { [Convert]::ToString($_, 2) } )" -replace '[\s0]'
 
            return $Bits.Length
        }
    }

#endregion

#region MAIN
    clear-host
    $defaultSite = "<yourSite>"
    get-inputCSV "<yourFile>.csv" | 
        % {$si = $_ #Subnet Info        
            $city = $state = $address = $region = $country = ""
            $Location = ""
            $city = ($si.city).trim()
            $state = ($si.state).trim()
            $address = ($si.address).trim()
            $region = ($si.region).trim()
            $country = ($si.country).trim()
            $subnet = ($si.'Wired Subnet').Trim()
            $prefix = (convertto-masklength $si.'mask ')
            if ($state -eq "") {
                $location = "$City, $Country"
            }
            else {
                $location = "$City, $State ($Country)"
            }
            new-object -TypeName psobject -Property @{'Location'=$location
                                                      'Description'="$region | $country | $state | $city | $address"
                                                      'SubnetName'="$subnet/$prefix"}
        } | % {
                $_
                New-ADReplicationSubnet -name $_.subnetName -site $defaultSite -Description $_.description -Location $_.location 
            }
#endregion
