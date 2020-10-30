Import-Module ActiveDirectory
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$objIPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$strDNSDomain = $objIPProperties.DomainName.toLower()
$strDomainDN = $strDNSDomain.toString().split('.'); foreach ($strVal in $strDomainDN) { $strTemp += "dc=$strVal," }; $strDomainDN = $strTemp.TrimEnd(",").toLower()
#Region Functions
Function SearchAD ($Asset) {
    if ($Asset -Match "^\d{6}$") {
        $Computer = Get-ADComputer -Filter ('Name -Like "*{0}*"' -f $Asset)
        $MovButton.Visible, $DelButton.Visible = $True, $True
        $InfoLabel.ForeColor, $InfoLabel.Font = "#5486d1", 'Microsoft Sans Serif,10,style=Bold'
        $InfoLabel.Text = $Computer.Name
        $Info = $Computer.DistinguishedName.toString() -split "," 
        ForEach ($_ in $Info) {
            $CompInfo.Text += $_ + [System.Environment]::NewLine
        }
    }
    Else {
        $CompInfo.Text = Clear-Host
        $InfoLabel.ForeColor, $InfoLabel.Text = 'Red', "Invalid Asset Tag Number"
        $MovButton.Visible, $DelButton.Visible = $False, $False
    }
}
Function DelComp($CompName) {
    Remove-ADComputer -Name $CompName 
}
Function AddNode ($SelectedNode, $Name) { 
    $NewNode = new-object System.Windows.Forms.TreeNode  
    $NewNode.Name = $name 
    $NewNode.Text = $name 
    [void] $SelectedNode.Nodes.Add($NewNode)
    return $NewNode 
}
Function GetNextLevel ($selectedNode, $dn) {

    $OUs = Get-ADObject -Filter 'ObjectClass -eq "organizationalUnit"' -SearchScope OneLevel -SearchBase $dn

    If ($null -eq $OUs) {
        $Node = AddNode $SelectedNode $dn
    }
    Else {
        $Node = AddNode $SelectedNode $dn
        
        $OUs | ForEach-Object {
            GetNextLevel $node $_.distinguishedName
        }
    }
}
Function BuildTreeView { 
    if ($treeNodes) {  
        $ADTree.Nodes.remove($treeNodes) 
        $Form.Refresh() 
    } 
    
    $TreeNodes = New-Object System.Windows.Forms.TreeNode 
    $TreeNodes.text = "PCC-Domain" 
    $TreeNodes.Name = "PCC-Domain" 
    $TreeNodes.Tag = "root" 
    [void] $ADTree.Nodes.Add($TreeNodes)  
     
    $ADTree.add_AfterSelect( { 
            $SelectBox.Text = $this.SelectedNode.Name
        }) 
     
    GetNextLevel $treeNodes $strDomainDN
    
    $TreeNodes.Expand() 
}
Function Prompt {
        $Prompt = New-Object System.Windows.Forms.Form
        $Prompt.StartPosition = 'CenterScreen'
        $Prompt.ClientSize = '220,100'
        $Prompt.BackColor = "#393b3b"
        $Prompt.ForeColor = "#5486d1"

        #$PimaIcon = New-Object System.Drawing.Icon ('.\favicon.ico')
        #$Form.Icon = $PimaIcon

        $PromptLabel = New-Object System.Windows.Forms.Label
        $PromptLabel.Font = 'Microsoft Sans Serif,style=Bold'
        $PromptLabel.Text = "Delete This Asset?"
        $PromptLabel.AutoSize = $True
        $PromptLabel.Location = New-Object System.Drawing.Point(50, 20)

        $YesButton = New-Object System.Windows.Forms.Button
        $YesButton.Text = 'Yes'
        $YesButton.Location = New-Object System.Drawing.Point(20, 65)
        $YesButton.Size = New-Object System.Drawing.Size(75, 23)

        $NoButton = New-Object System.Windows.Forms.Button
        $NoButton.Text = 'No'
        $NoButton.Location = New-Object System.Drawing.Point(120, 65)
        $NoButton.Size = New-Object System.Drawing.Size(75, 23)
        $NoButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

        $Prompt.Controls.AddRange(@($PromptLabel, $YesButton, $NoButton))

}
#EndRegion
#Region UI
$Form = New-Object System.Windows.Forms.Form
$Form.text = "Pima WC Computer Manager - Active Directory"
$Form.StartPosition = 'CenterScreen'
$Form.ClientSize = '600,400'
$Form.BackColor = "#393b3b"
$Form.ForeColor = "#5486d1"

$PimaIcon = New-Object System.Drawing.Icon ('.\favicon.ico')
$Form.Icon = $PimaIcon

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Enter the Device Asset Tag Number"
$Label.Location = New-Object System.Drawing.Point(20, 20)
$Label.TextAlign = 'TopLeft'
$Label.AutoSize = $True
$Label.Font = 'Microsoft Sans Serif,10,style=Bold'

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Location = New-Object System.Drawing.Point(20, 45)
$TextBox.BackColor = "#737880"
$TextBox.ForeColor = "#080a1a"
$TextBox.AutoSize = $True

$FindButton = New-Object System.Windows.Forms.Button
$FindButton.Text = "Search"
$FindButton.Location = New-Object System.Drawing.Point(125, 45)
$FindButton.AutoSize = $True

$InfoLabel = New-Object System.Windows.Forms.Label
$InfoLabel.Location = New-Object System.Drawing.Point(20, 90)
$InfoLabel.AutoSize = $True
$InfoLabel.Font = 'Microsoft Sans Serif'


$CompInfo = New-Object System.Windows.Forms.TextBox
$CompInfo.Location = New-Object System.Drawing.Point(20, 110)
$CompInfo.Height = 200
$CompInfo.Width = 250
$CompInfo.BackColor = "#737880"
$CompInfo.ForeColor = "#080a1a"
$CompInfo.ReadOnly = $True
$CompInfo.Multiline = $True
$CompInfo.ScrollBars = "Both"

$StatusBar = New-Object System.Windows.Forms.StatusBar
$StatusBar.Text = "Ready"

$MovButton = New-Object System.Windows.Forms.Button
$MovButton.Text = "Move"
$MovButton.Location = New-Object System.Drawing.Point(115, 315)
$MovButton.AutoSize = $True
$MovButton.Visible = $False

$DelButton = New-Object System.Windows.Forms.Button
$DelButton.Text = "Delete"
$DelButton.Location = New-Object System.Drawing.Point(195, 315)
$DelButton.AutoSize = $True
$DelButton.Visible = $False

$ADLabel = New-Object System.Windows.Forms.Label
$ADLabel.Text = "Active Directory Tree"
$ADLabel.Location = New-Object System.Drawing.Point(365, 20)
$ADLabel.Visible = $False
$ADLabel.AutoSize = $True
$ADLabel.Font = 'Microsoft Sans Serif,10,style=Bold'

$ADTree = New-Object System.Windows.Forms.TreeView
$ADTree.Visible = $False
$ADTree.Size = New-Object System.Drawing.Size(275, 250)
$ADTree.Location = New-Object System.Drawing.Size(300, 60)
$ADTree.Scrollable = $True
$ADTree.BackColor = "#737880"
$ADTree.ForeColor = "#080a1a"

$SelectBox = New-Object System.Windows.Forms.TextBox
$SelectBox.Location = New-Object System.Drawing.Point(300, 315)
$SelectBox.BackColor = "#737880"
$SelectBox.ForeColor = "#080a1a"
$SelectBox.Size = New-Object System.Drawing.Point(275, 10)
$SelectBox.Visible = $False

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Text = 'OK'
$OKButton.Location = New-Object System.Drawing.Point(430, 350)
$OKButton.Size = New-Object System.Drawing.Size(75, 23)
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

$CloseButton = New-Object System.Windows.Forms.Button
$CloseButton.Text = 'Close'
$CloseButton.Location = New-Object System.Drawing.Point(510, 350)
$CloseButton.Size = New-Object System.Drawing.Size(75, 23)
$CloseButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
 

$Form.Controls.AddRange(@($Label, $TextBox, $CompInfo, $FindButton, $InfoLabel, $StatusBar, $MovButton, $DelButton, $ADLabel, $ADTree, $SelectBox, $OKButton, $CloseButton))
#EndRegion
#Region Events
$FindButton.Add_Click( {
        $StatusBar.Text = "Searching Active Directory.."
        SearchAD -Asset $TextBox.Text
        Start-Sleep -s 1
        $StatusBar.Text = "Done.."
        Start-Sleep -s 1
        $StatusBar.Text = Clear-Host
    })

$MovButton.Add_Click( {
        $StatusBar.Text = "Select an OU.."
        $ADLabel.Visible = $True
        $ADTree.Visible = $True
        $SelectBox.Visible = $True
        BuildTreeView
    })

$DelButton.Add_Click( {

        Prompt

        $StatusBar.Text = "Deleting Computer.."
        Start-Sleep -s 1
        #DelComp -CompName $InfoLabel.Text
        $StatusBar.Text = "Done.."
        Start-Sleep -s 1
        $StatusBar.Text = ''
    })

$CloseButton.Add_Click( {
        $StatusBar.Text = "Closing..Good Bye"
        Start-Sleep -s 1 
    })
#endregion



[void]$Form.ShowDialog()