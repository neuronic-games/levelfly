require 'rubygems'
require 'aws/s3'
class Attachment < ActiveRecord::Base
  belongs_to :tasks
  @@aws_bucket = nil
  
  def self.aws_bucket(bucket)
    @@aws_bucket = bucket
  end
  
  def self.aws_connection(school_id)
    connect = false
    if school_id
      @vault = Vault.find(:first, :conditions => ["object_id = ? AND object_type='School' AND vault_type= 'AWS S3'", school_id])
      if @vault
        self.aws_bucket(@vault.folder)
        if AWS::S3::Base.establish_connection!(
            :access_key_id     => @vault.account,
            :secret_access_key => @vault.secret
          )
          connect = true
        end
      end
    end
    return connect
  end
  
  def self.aws_upload(school_id, filename, temp_path)
    if self.aws_connection(school_id)
      base_name = File.basename(filename)
      AWS::S3::S3Object.store(
        base_name,
        File.open(temp_path.path),
        @@aws_bucket
      )
    else
      puts 'not connect!!'
    end
  end
end
