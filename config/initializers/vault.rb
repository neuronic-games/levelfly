# Read the credentials for the data vault: AWS S3

Paperclip.interpolates :school do |attachment, style|
  attachment.instance.school_id
end

Paperclip.interpolates :course do |attachment, style|
  attachment.instance.course_id
end

Paperclip.interpolates :id do |attachment, style|
  attachment.instance.id
end

vault = Vault.last

Vault.default_account = vault.account
Vault.default_secret = vault.secret
Vault.default_folder = vault.folder