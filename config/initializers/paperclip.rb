Paperclip.interpolates :school do |attachment, _style|
  attachment.instance.school_id
end

Paperclip.interpolates :course do |attachment, _style|
  attachment.instance.course_id
end

Paperclip.interpolates :id do |attachment, _style|
  attachment.instance.id
end

Paperclip.interpolates :target do |attachment, _style|
  attachment.instance.target_type
end

Paperclip.interpolates :target_id do |attachment, _style|
  attachment.instance.target_id
end
