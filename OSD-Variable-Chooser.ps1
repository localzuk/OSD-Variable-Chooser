#MIT License
#
#Copyright (c) 2022 Anthony Ayre
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

#-------------------------------------------------------------#
#----Initial Declarations-------------------------------------#
#-------------------------------------------------------------#

Add-Type -AssemblyName PresentationCore, PresentationFramework

#GUI
$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Width="800" Height="300" Name="mainForm">

<Grid HorizontalAlignment="Left" VerticalAlignment="Top" Width="798" Height="256" Margin="0,0,0,0">
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Device Setup - Enter name and device details" Margin="10,10,0,0" FontSize="16" FontWeight="Bold"/>    
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Select Site:" Margin="10,55,0,0"/>
<ComboBox HorizontalAlignment="Left" VerticalAlignment="Top" Width="359" Margin="125,50,0,0" Name="cmbSite" Height="32"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Select OU:" Margin="10,105,0,0"/>
<ComboBox HorizontalAlignment="Left" VerticalAlignment="Top" Width="359" Margin="125,100,0,0" Name="cmbOU" Height="32"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Device Type:" Margin="10,155,0,0"/>
<ComboBox HorizontalAlignment="Left" VerticalAlignment="Top" Width="359" Margin="125,150,0,0" Name="cmbDeviceType" Height="32"/>
<Label HorizontalAlignment="Left" VerticalAlignment="Top" Content="Asset ID:" Margin="10,205,0,0"/>
<TextBox HorizontalAlignment="Left" VerticalAlignment="Top" Height="44" Width="357" TextWrapping="Wrap" Margin="125,200,0,0" Name="tbxAssetID"/>
<Image HorizontalAlignment="Left" Height="80" VerticalAlignment="Top" Width="275" Margin="506,15,0,0" Name="imgLogo"/>
<Button Content="Continue" HorizontalAlignment="Left" VerticalAlignment="Top" Width="115" Margin="506,200,0,0" Height="44" Name="btnContinue"/>
<TextBlock HorizontalAlignment="Left" VerticalAlignment="Top" TextWrapping="Wrap" Text="" Margin="506.5,101.984375,0,0" Name="tbbErrors" Width="268" Height="79"/>
</Grid>
</Window>
"@

#-------------------------------------------------------------#
#----Control Event Handlers-----------------------------------#
#-------------------------------------------------------------#


#region Logic

$filePath = ".\config.json"

#Hide Progress Bar
Try
{
	$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
	$TSProgressUI.CloseProgressDialog()
	$TSProgressUI = $null
}
Catch
{
	LogIt "Could not find the TSProgressUI" -type Warning
	Log-Error $_
}

#LoadJSON
$dtHash = @{}
(Get-Content $filePath | ConvertFrom-Json).psobject.properties | Foreach { $dtHash[$_.Name] = $_.Value }

#GetLogo
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$imagePath = Join-Path $scriptPath "logo.png"

#Sites
function Load-Sites {
    $cmbSite.ItemsSource = $dtHash.sites
    $cmbSite.SelectedValuePath = "Value"
    $cmbSite.DisplayMemberPath = "Text"
}

#DeviceTypes
function Load-DeviceTypes {
    $cmbDeviceType.ItemsSource = $dtHash.deviceTypes
    $cmbDeviceType.SelectedValuePath = "Value"
    $cmbDeviceType.DisplayMemberPath = "Text"
}
#Load In PNG logo
function Load-Logo {
    $imgLogo.Source = $imagePath
}
#Update the OU list based on Site selection
function Update-OU-List {
    $cmbOU.ItemsSource = $null
    $cmbOU.Items.Clear()
    $cmbSelectedValue = $cmbSite.SelectedValue
    $cmbOU.ItemsSource = @($dtHash.ous.$($cmbSelectedValue).Values)
    $cmbOU.SelectedValuePath = "Value"
    $cmbOU.DisplayMemberPath = "Text"
}

#Set up the form via JSON
function Setup-Form {
    Load-Logo
    Load-Sites
    Load-DeviceTypes
}

function ContinueOSD {
    #Validations
    $validSite = $true
    $validOU = $true
    $validDeviceType = $true
    $validAssetIDPrefix = $true
    $validAssetIDLength = $true
    $validAssetIDEmpty = $true
    
    #Check site is selected
    if($cmbSite.SelectedValue -eq $null){
        $time = (get-date).ToString('T')
        $tbbErrors.Text = ("$time - You haven't selected a site`r`n") + $tbbErrors.Text
        $cmbSite.BorderBrush = "#ba2733"
        $validSite = $false
    } else {
        $validSite = $true
    }
    
    #Check OU is selected
    if($cmbOU.SelectedValue -eq $null){
        $time = (get-date).ToString('T')
        $tbbErrors.Text = ("$time - You haven't selected an OU`r`n") + $tbbErrors.Text
        $cmbOU.BorderBrush = "#ba2733"
        $validOU = $false
    } else {
        $validOU = $true
    }
    
    #Check Device Type is selected
    if($cmbDeviceType.SelectedValue -eq $null){
        $time = (get-date).ToString('T')
        $tbbErrors.Text = ("$time - You haven't selected a device type`r`n") + $tbbErrors.Text
        $cmbDeviceType.BorderBrush = "#ba2733"
        $validDeviceType = $false
    } else {
        $validDeviceType = $true
    }
    
    #Validate asset ID
    $length = $dtHash.AssetIDLength
    $maxPrefixLength = $dtHash.maxAssetIDPrefixLength
    [string]$validIDPrefixes = $dtHash.validIDPrefixes
	#Check Asset ID length
    if($tbxAssetID.Text.Length -ne 0){
        $validAssetIDEmpty = $true
		#Check Asset ID prefix
        if (-not $validIDPrefixes.Contains($tbxAssetID.Text.substring(0,$maxPrefixLength))){
            $time = (get-date).ToString('T')
            $tbbErrors.Text = ("$time - Invalid Asset ID prefix`r`n") + $tbbErrors.Text
            $tbxAssetID.BorderBrush = "#ba2733"
            $validAssetIDPrefix = $false
        } else {
            $validAssetIDPrefix = $true
        }
		#Check Asset ID max length
        if ($tbxAssetID.Text.Length -ne $length){
            $time = (get-date).ToString('T')
            $tbbErrors.Text = ("$time - Invalid Asset ID length`r`n") + $tbbErrors.Text
            $tbxAssetID.BorderBrush = "#ba2733"
            $validAssetIDLength = $false
        } else {
            $validAssetIDLength = $true
        }
    } else {
		#Asset ID is empty
        $time = (get-date).ToString('T')
        $tbbErrors.Text = ("$time - Asset ID is empty`r`n") + $tbbErrors.Text
        $tbxAssetID.BorderBrush = "#ba2733"
        $validAssetIDEmpty = $false
    }
    
	#Check all fields are set correctly, and process
    if($validAssetIDPrefix -ne $false -and $validAssetIDLength -ne $false -and $validAssetIDEmpty -ne $false -and $validSite -ne $false -and $validOU -ne $false -and $validDeviceType -ne $false){
        #Set Variables
        $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
        $tsenv.Value("osdjoindomainouname") = $cmbOU.SelectedValue
        $prefix = $cmbDeviceType.SelectedValue
        $assetID = $tbxAssetID.Text
        $deviceName = "$prefix$assetID"
        $tsenv.Value("OSDComputerName") = $deviceName
		
		#Show OSD Progress Bar again
        Try
        {
            $TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
            $TSProgressUI.ShowTSProgress($tsenv.Value("_SMSTSOrgName"), $tsenv.Value("_SMSTSPackageName"), $tsenv.Value("_SMSTSCustomProgressDialogMessage"), $tsenv.Value("_SMSTSCurrentActionName"), $tsenv.Value("_SMSTSNextInstructionPointer"), $tsenv.Value("_SMSTSInstructionTableSize"))
            $TSProgressUI = $null
        }
        Catch
        {
            LogIt "Could not find the TSProgressUI" -type warning
        }
		
		#Exit
        $Window.Close()
        Exit
    }
}
#endregion 

#-------------------------------------------------------------#
#----Script Execution-----------------------------------------#
#-------------------------------------------------------------#

$Window = [Windows.Markup.XamlReader]::Parse($Xaml)

[xml]$xml = $Xaml

$xml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name $_.Name -Value $Window.FindName($_.Name) }

$mainForm.Add_Loaded({Setup-Form $this $_})
$cmbSite.Add_SelectionChanged({Update-OU-List $this $_})
$btnContinue.Add_Click({ContinueOSD $this $_})

$Window.ShowDialog()


