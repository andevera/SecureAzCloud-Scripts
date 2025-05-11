#Default Policy to Block all mailboxes in the tenant from configuring Personal accounts:
Set-OwaMailboxPolicy -Identity "OwaMailboxPolicy-Default" -PersonalAccountsEnabled $false

#If you prefer to apply this restriction to a subset of users, consider creating a custom OWA mailbox policy:
New-OwaMailboxPolicy -Name "NoPersonalAccountsPolicy"
Set-OwaMailboxPolicy -Identity "NoPersonalAccountsPolicy" -PersonalAccountsEnabled $false

#Then, assign this policy to specific mailboxes:
Set-CASMailbox -Identity user@domain.com -OwaMailboxPolicy "NoPersonalAccountsPolicy"

#Verify
Get-OwaMailboxPolicy -Identity "OwaMailboxPolicy-Default" | Format-List Name,PersonalAccountsEnabled
