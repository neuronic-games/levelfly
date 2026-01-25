FactoryBot.define do
  factory :attachment do
    resource_file_name { Faker::File.file_name }
    resource_content_type { Faker::File.mime_type }
  end
end
