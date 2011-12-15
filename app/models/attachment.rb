require 'rubygems'
require 'aws/s3'
class Attachment < ActiveRecord::Base
  belongs_to :tasks
  
  def self.aws_bucket(bucket)
    
    create = true
    begin
      AWS::S3::Bucket.find(bucket)
      create = false
    rescue
    end

    begin
      if create
        AWS::S3::Bucket.create(bucket)
      end
    rescue
    end
    
  end
  
  def self.aws_connection(school_id)
    @vault = nil
    if school_id
      @vault = Vault.find(:first, 
        :conditions => ["object_id = ? and object_type = 'School' and vault_type = 'AWS S3'", school_id])
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
    return @vault
  end
  
  def self.aws_upload(school_id, filename, temp_path)
    @vault = self.aws_connection(school_id)
    if @vault
      base_name = File.basename(filename)
      AWS::S3::S3Object.store(
        base_name,
        File.open(temp_path.path),
        @vault.folder,
        :access => :public_read
      )
    else
      puts 'not connect!!'
    end
  end
end
