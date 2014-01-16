Paperclip.interpolates :school do |attachment, style|
  attachment.instance.school_id
end

Paperclip.interpolates :course do |attachment, style|
  attachment.instance.course_id
end

Paperclip.interpolates :id do |attachment, style|
  attachment.instance.id
end

Paperclip.interpolates :target do |attachment, style|
  attachment.instance.target_type
end

Paperclip.interpolates :target_id do |attachment, style|
  attachment.instance.target_id
end
