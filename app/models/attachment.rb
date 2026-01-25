require 'rubygems'
require 'aws-sdk-s3'
require 'open-uri'

class Attachment < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :school
  belongs_to :owner, class_name: 'Profile'

  acts_as_taggable
  has_attached_file :resource,
                    path: "#{ENV.fetch('S3_PATH', '')}schools/:school/files/:target/:target_id/:filename"
  # TODO: This is the correct solution to allow for files of the same name, but we need to write a script to move all files to the new location
  # :path => "schools/:school/files/:target/:target_id/:id/:filename"

  # FIXME: https://stackoverflow.com/a/21898204/14269772
  do_not_validate_attachment_file_type :resource

  def self.aws_connection(school_id)
    client = false
    # @vault = nil
    if school_id
      # @vault = Vault.find(:first,
      # :conditions => ["target_id = ? and target_type = 'School' and vault_type = 'AWS S3'", school_id])
      # if @vault
      client = Aws::S3::Client.new
      # end
    end
    client
  end

  def self.aws_ensure_bucket(client, bucket = nil)
    bucket = ENV.fetch('S3_BUCKET') if bucket.nil?
    client.create_bucket({ bucket: bucket }) unless client.list_buckets.buckets.map(&:name).include? bucket
    bucket
  end

  def self.aws_upload(school_id, filename, temp_image_path)
    client = aws_connection(school_id)
    bucket = aws_ensure_bucket(client)
    path = ENV.fetch('S3_PATH', '')
    filename = "#{path}#{filename}"
    if client
      client.put_object(bucket: bucket, acl: :public_read, key: filename, body: File.read(temp_image_path))
    else
      puts "Error uploading #{filename}"
    end
  end

  def self.aws_upload_base64(school_id, bucket_name = nil, filename, base64)
    client = aws_connection(school_id)
    bucket_name = aws_ensure_bucket(client, bucket_name)
    path = ENV.fetch('S3_PATH', '')
    filename = "#{path}#{filename}"
    if client
      logger.info "(aws_upload_base64) school_id: #{school_id}, bucket_name: #{bucket_name}, filename: #{filename}"
      client.put_object(bucket: bucket_name, key: filename, body: base64)
    else
      logger.error "(aws_upload_base64) Error uploading, school_id: #{school_id}, bucket_name: #{bucket_name}, filename: #{filename}"
    end
  end

  def self.aws_get_file_data(school_id, filename, bucket_name = nil)
    client = aws_connection(school_id)
    bucket_name = aws_ensure_bucket(client, bucket_name)
    path = ENV.fetch('S3_PATH', '')
    filename = "#{path}#{filename}"
    if client
      client.get_object(bucket: bucket_name, key: filename).body.read
    else
      puts "Error fetching #{filename} from #{bucket}"
    end
  end

  def self.aws_delete_file(school_id, filename, bucket_name = nil)
    client = aws_connection(school_id)
    bucket_name = aws_ensure_bucket(client, bucket_name)
    path = ENV.fetch('S3_PATH', '')
    filename = "#{path}#{filename}"
    if connection
      client.delete_object(bucket: bucket_name, key: filename)
    else
      puts "Error deleting #{filename} from #{bucket}"
    end
  end
end
