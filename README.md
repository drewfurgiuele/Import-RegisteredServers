# Import-RegisteredServers

Did you want to copy all your currently registered servers in SQL Server Management Studio over to SQL Operations Studio? Me too. This script will do just that.

## Requirements

Make sure you have the SQL Server PowerShell Module loaded. You can get it here: https://www.powershellgallery.com/packages/SqlServer/

## Notes

This is rough and needs some more work, but it works for me. It won't copy any credentials over (yet). I'll also put a proper help section together soon.

## Other important bits:

1. This requires the SQL Server PowerShell Module. Get it here: https://www.powershellgallery.com/packages/SqlServer/
2. This will modify and then overwrite your settings. It makes a backup. But you should know it does this.
3. Run SQL Operations Studio once to generate a settings file before you start.