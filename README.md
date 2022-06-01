# Setup

Configure the config.json to match your needs.

Specify your AD layout: 
- Sites (note, these are effectively just folders), 
- OUs (these are dependent on the value of each site you set up), 
- Device types (these form the basis of the device name, 
- Asset ID Prefixes, 
- maximum asset ID prefix length, 
- maximum asset ID length.

Your logo should be saved as a png file called logo.png in the root of the same directory as the script.

# MECM Usage

Create a package containing the 3 files - config.json, OSD-Chooser.ps1 and your logo.png. The package does not have a program.
In your OSD Task Sequence, add a powershell step near the start. Specify the package you added in the last step, and enter the OSD-Chooser.ps1 script as the script to run.
Change the execution policy to Bypass.

Ensure you distribut the package to your distribution points.

## Config Example:

```
{
	"sites": [{
		"Text": "Central Team",
		"Value": "CENT"
	}, {
		"Text": "Branch 1",
		"Value": "BRAN1"
	}],
	"ous": [{
			"CENT": {
				"Values":[{
					"Text": "WSAT Desktops",
					"Value": "LDAP://OU=Desktops,OU=CENT,OU=Managed Devices,DC=domain,DC=example"
					},{
					"Text": "WSAT Desktops - IT Admin",
					"Value": "LDAP://OU=Laptops,OU=CENT,OU=Managed Devices,DC=domain,DC=example"
					}
				}
			},{
			"BRAN1":{
				"Values":[{
					"Text": "BRAN1 Admin Desktops",
					"Value": "LDAP://OU=Desktops,OU=Admin,OU=Branch 1,OU=Managed Devices,DC=domain,DC=example"
					}]
				}
			}
		],			
	"deviceTypes": [{
		"Text": "Desktop PC",
		"Value": "DES"
	},{
		"Text": "Laptop",
		"Value": "LAP"
	},{
		"Text": "Tablet",
		"Value": "TAB"
	}],
	"validIDPrefixes": [2505, 2715, 2733, 3000],
	"maxAssetIDPrefixLength": 4,
	"AssetIDLength": 8		
}
```
