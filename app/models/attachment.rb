require 'rubygems'
require 'aws/s3'
require 'open-uri'

class Attachment < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :school
  belongs_to :owner, :class_name => "Profile"
  
  acts_as_taggable
  has_attached_file :resource,
    :storage => :s3,
    :s3_credentials => { :access_key_id => ENV['S3_KEY'], :secret_access_key => ENV['S3_SECRET'] },
    :path => "schools/:school/files/:target/:target_id/:filename",
    # :path => "schools/:school/files/:target/:target_id/:id/:filename",  This is the correct solution to allow for files of the same name, but we need to write a script to move all files to the new location
    :bucket => ENV['S3_PATH'],
    :s3_protocol => ENV['S3_PROTOCOL']

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
  
  def self.aws_connection(school_id, bucket=nil)
    connect = false
    #@vault = nil
    if school_id
      #@vault = Vault.find(:first,
      #:conditions => ["target_id = ? and target_type = 'School' and vault_type = 'AWS S3'", school_id])
      #if @vault
        self.aws_bucket(bucket ? bucket : ENV['S3_PATH'])
        connect = AWS::S3.new(
            :access_key_id     => ENV['S3_KEY'],
            :secret_access_key => ENV['S3_SECRET']
          )
      #end
    end
    return connect
  end
  
  def self.aws_upload(school_id, filename, temp_image_path)
    connection = self.aws_connection(school_id)
    if connection
      base_name = File.basename(filename)
      file_to_upload = File.open(temp_image_path)
      bucket = connection.buckets[ENV['S3_PATH'] + 'resources']
      obj = bucket.objects[base_name]
      obj.write(file_to_upload, :acl => :public_read)
    else
      puts "Error uploading #{filename}"
    end
  end

  def self.aws_upload_base64(school_id, bucket, filename, base64)
    connection = self.aws_connection(school_id, bucket)
    if connection
      base_name = File.basename(filename)
      puts "#{bucket}, #{base_name}"
      bucket = connection.buckets[bucket]
      obj = bucket.objects[base_name]
      obj.write(base64, :acl => :public_read)
    else
      puts "Error uploading #{filename} to #{bucket}"
    end
  end
  
  def self.aws_get_file_data(school_id, filename, bucket)
    connection = self.aws_connection(school_id, bucket)
    if connection
      base_name = File.basename(filename)
      puts "#{bucket}, #{base_name}"
      obj = connection.buckets[bucket].objects[base_name]
      obj.read
    else
      puts "Error uploading #{filename} to #{bucket}"
    end
  end
  
  def self.aws_delete_file(school_id, filename, bucket)
    connection = self.aws_connection(school_id, bucket)
    if connection
      base_name = File.basename(filename)
      AWS::S3::S3Object.delete(base_name, bucket)
    else
      puts "Error uploading #{filename} to #{bucket}"
    end
  end
end
