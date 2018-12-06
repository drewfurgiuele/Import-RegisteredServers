# Import-RegisteredServers

Did you want to copy all your currently registered servers in SQL Server Management Studio over to Azure Data Studio? Me too. This function will do just that.

If you want to read more about how the script was constructed or to see a demo, visit: http://www.port1433.com

## Requirements

Make sure you have the SQL Server PowerShell Module loaded. You can get it here: https://www.powershellgallery.com/packages/SqlServer/

## Important Notes:

1. It’s mentioned above, but bears repeating: this requires the SQL Server PowerShell module. Go download it already!
2. If you run the script and you see servers show up in your settings, but not in Azure Data Studio, try restarting the application. It can be a little finicky about that.
3. The function can take two optional parameters:
   1. `-PathToSettingsFile`  will allow you to specify a different user settings file. By default, the script will read your $env:AppData  variable to determine the default location, but if it can’t find it there, you can override where it looks with this parameter.
   2. `-SaveTo`  is similar, except your have your output saved somewhere else instead of overwriting your existing file
4. Oh, before you panic about that last bit: the script will take your existing file, whether it be the default or one you specify and make a copy with it a “.old” extension at the end.
5. The script will check for duplicates when you run it. Meaning: if you run it once and import your stuff, it won’t duplicate all your folders and servers again. However, it you were to add a new registration to your SSMS 6. registered servers, and then re-run the script, you should only get the new stuff. It makes the script a little more complicated with some checking, but in the end I didn’t want people creating an endless stream of servers.
7. Try running it with -Verbose  for some updates. I wrote this hopped up on prescription cough medicine, so it’ll be fun to re-read these messages later.
8. A note on authentication methods: if you have SQL Server Authentication for any existing registered servers in SSMS, your credentials will be pulled and saved in plain text in your settings file. I know, I know, but that’s how I pull them from PowerShell (it’s plain text there, too). I haven’t found a neat way to save those credentials encrypted, yet.
