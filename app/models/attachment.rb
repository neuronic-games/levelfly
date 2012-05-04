require 'rubygems'
require 'aws/s3'
class Attachment < ActiveRecord::Base
  belongs_to :object, :polymorphic => true
  belongs_to :school
  acts_as_taggable
  has_attached_file :resource,
    :storage => :s3,
    :s3_credentials => { :access_key_id => School.vault.account, :secret_access_key => School.vault.secret },
    :path => "schools/:school/files/:object/:object_id/:filename",
    :bucket => School.vault.folder

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
  
  def self.aws_upload(school_id, filename, temp_image, dataURL=false)
    @vault = self.aws_connection(school_id)
    if @vault
      base_name = File.basename(filename)
      file_to_upload = dataURL ? temp_image : File.open(temp_image)
      bucket_folder = dataURL ? @vault.folder+"/avatar_thumb" : @vault.folder+"/resources" 
      AWS::S3::S3Object.store(
        base_name,
        file_to_upload,
        bucket_folder,
        :access => :public_read
      )
    else
      puts 'not connect!!'
    end
  end
end
