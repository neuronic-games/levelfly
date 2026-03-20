class Attachment < ActiveRecord::Base
  belongs_to :target, polymorphic: true
  belongs_to :school
  belongs_to :owner, class_name: 'Profile'

  acts_as_taggable
  has_one_attached :resource

  def self.upload_base64(_school_id, filename, base64_data)
    require 'base64'
    require 'tempfile'

    decoded_data = Base64.decode64(base64_data)

    attachment = Attachment.new
    attachment.resource.attach(
      io: StringIO.new(decoded_data),
      filename: filename,
      content_type: determine_content_type(filename)
    )

    attachment
  end

  def self.get_file_data(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return nil unless attachment&.resource&.attached?

    attachment.resource.download
  end

  def self.delete_file(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return unless attachment&.resource&.attached?

    attachment.resource.purge
  end

  def self.determine_content_type(filename)
    case File.extname(filename).downcase
    when '.jpg', '.jpeg' then 'image/jpeg'
    when '.png' then 'image/png'
    when '.gif' then 'image/gif'
    when '.pdf' then 'application/pdf'
    when '.doc', '.docx' then 'application/msword'
    when '.xls', '.xlsx' then 'application/vnd.ms-excel'
    when '.ppt', '.pptx' then 'application/vnd.ms-powerpoint'
    when '.zip' then 'application/zip'
    when '.txt' then 'text/plain'
    when '.csv' then 'text/csv'
    else 'application/octet-stream'
    end
  end
end
