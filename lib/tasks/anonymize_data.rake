# frozen_string_literal: true

require 'faker'

namespace :levelfly do
  desc 'Anonmyize user data'
  task anonymize_data: :environment do
    $stdout.puts 'WARNING: This will reset all user emails and names. Continue? [yN]'
    input = $stdin.gets.chomp
    raise 'Aborting' unless input == 'y'

    profiles = Profile.where.not(role_name: RoleName.find_by(name: 'Levelfly Admin'))
    profiles.find_in_batches(batch_size: 1000) do |batch|
      values = batch.map { |p| "(#{p.id}, '#{Faker::Name.name.gsub("'", "''")}')" }.join(', ')
      sql = <<~SQL
        UPDATE profiles#{' '}
        SET full_name = updates.new_name
        FROM (VALUES #{values}) AS updates(id, new_name)
        WHERE profiles.id = updates.id
      SQL
      Profile.connection.execute(sql)
    end

    User.find_in_batches(batch_size: 1000) do |batch|
      values = batch.map do |u|
        email = Faker::Internet.email.gsub("'", "''")
        current_ip = Faker::Internet.ip_v4_address
        last_ip = Faker::Internet.ip_v4_address
        "(#{u.id}, '#{email}', '#{current_ip}', '#{last_ip}')"
      end.join(', ')

      sql = <<~SQL
        UPDATE users#{' '}
        SET#{' '}
          email = updates.email,
          current_sign_in_ip = updates.current_ip,
          last_sign_in_ip = updates.last_ip,
          unconfirmed_email = NULL,
          updated_at = NOW()
        FROM (VALUES #{values}) AS updates(id, email, current_ip, last_ip)
        WHERE users.id = updates.id
      SQL
      User.connection.execute(sql)
    end

    Message.find_in_batches(batch_size: 1000) do |batch|
      values = batch.map do |m|
        content = Faker::Lorem.paragraphs(number: 2).join("\n\n").gsub("'", "''")
        "(#{m.id}, '#{content}')"
      end.join(', ')

      sql = <<~SQL
        UPDATE messages#{' '}
        SET content = updates.content, updated_at = NOW()
        FROM (VALUES #{values}) AS updates(id, content)
        WHERE messages.id = updates.id
      SQL
      Message.connection.execute(sql)
    end
  end
end
