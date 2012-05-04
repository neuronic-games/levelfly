# Read the credentials for the data vault: AWS S3

vault = Vault.last

Vault.default_account = vault.account
Vault.default_secret = vault.secret
Vault.default_folder = vault.folder