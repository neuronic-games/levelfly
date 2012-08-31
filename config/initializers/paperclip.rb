Paperclip.interpolates :school do |attachment, style|
  attachment.instance.school_id
end

Paperclip.interpolates :course do |attachment, style|
  attachment.instance.course_id
end

Paperclip.interpolates :id do |attachment, style|
  attachment.instance.id
end

Paperclip.interpolates :object do |attachment, style|
  attachment.instance.object_type
end

Paperclip.interpolates :object_id do |attachment, style|
  attachment.instance.object_id
end
