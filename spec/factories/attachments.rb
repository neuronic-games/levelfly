FactoryBot.define do
  factory :attachment do
    resource do
      Rack::Test::UploadedFile.new('app/assets/images/rails.png', 'image/png')
    end
  end
end
