namespace :migrate_paperclip_to_active_storage do
  desc 'Migrate Paperclip attachments from S3 to ActiveStorage local storage'
  task migrate: :environment do
    puts '=' * 80
    puts 'Starting Paperclip to ActiveStorage migration'
    puts '=' * 80

    # Configuration - S3 data location
    source_path = ENV.fetch('S3_DATA_PATH', Rails.root.join('tmp/s3_data'))

    unless Dir.exist?(source_path)
      puts "ERROR: Source path not found: #{source_path}"
      puts 'Set S3_DATA_PATH environment variable to point to local S3 bucket copy'
      exit 1
    end

    puts "Source path: #{source_path}"
    puts ''

    # Track migration statistics
    stats = {
      Task: { total: 0, success: 0, failed: 0, skipped: 0 },
      ScreenShot: { total: 0, success: 0, failed: 0, skipped: 0 },
      Group: { total: 0, success: 0, failed: 0, skipped: 0 },
      Game: { total: 0, success: 0, failed: 0, skipped: 0 },
      Course: { total: 0, success: 0, failed: 0, skipped: 0 },
      BadgeImage: { total: 0, success: 0, failed: 0, skipped: 0 },
      Attachment: { total: 0, success: 0, failed: 0, skipped: 0 }
    }

    # Migrate each model
    migrate_model(Task, :image, stats[:Task], source_path)
    migrate_model(ScreenShot, :image, stats[:ScreenShot], source_path)
    migrate_model(Group, :image, stats[:Group], source_path)
    migrate_model(Game, :image, stats[:Game], source_path)
    migrate_model(Course, :image, stats[:Course], source_path)
    migrate_model(BadgeImage, :image, stats[:BadgeImage], source_path)
    migrate_model(Attachment, :resource, stats[:Attachment], source_path)

    # Print statistics
    puts "\n" + ('=' * 80)
    puts 'Migration Complete'
    puts '=' * 80
    stats.each do |model_name, model_stats|
      puts "#{model_name}:"
      puts "  Total records: #{model_stats[:total]}"
      puts "  Success: #{model_stats[:success]}"
      puts "  Failed: #{model_stats[:failed]}"
      puts "  Skipped (already migrated): #{model_stats[:skipped]}"
    end
    puts '=' * 80

    total_success = stats.values.sum { |s| s[:success] }
    total_failed = stats.values.sum { |s| s[:failed] }
    if total_failed > 0
      puts "\nWARNING: #{total_failed} files failed to migrate. Check the logs above."
      exit 1
    end
  end

  def migrate_model(model_class, attachment_name, stats, source_path)
    puts "\nMigrating #{model_class.name}..."

    file_name_column = "#{attachment_name}_file_name"
    file_path_template = build_paperclip_path(model_class, attachment_name)

    # Batch process records to improve performance
    model_class.where.not(file_name_column => nil).find_each(batch_size: 100) do |record|
      stats[:total] += 1

      begin
        # Skip if already migrated to ActiveStorage
        if record.send(attachment_name).attached?
          stats[:skipped] += 1
          print 's' if stats[:skipped] % 10 == 0
          next
        end

        # Get filename
        filename = record.send(file_name_column)

        # Build source file path based on Paperclip's S3 structure
        paperclip_path = interpolate_path(record, file_path_template, attachment_name)
        source_file = File.join(source_path, ENV.fetch('S3_BUCKET', 'levelfly'), paperclip_path)

        # Check if file exists
        unless File.exist?(source_file)
          puts "\n  [WARN] File not found: #{source_file}"
          puts "    Record: #{model_class.name}##{record.id}"
          stats[:failed] += 1
          next
        end

        # Calculate checksum for integrity verification
        # Note: Checksum is used internally by ActiveStorage for file integrity
        checksum = calculate_checksum(source_file)

        # Get file size
        file_size = File.size(source_file)

        # Get content type from Paperclip metadata or infer from filename
        content_type = record.send("#{attachment_name}_content_type") ||
                       determine_content_type(filename)

        # Attach file to ActiveStorage
        record.send(attachment_name).attach(
          io: File.open(source_file),
          filename: filename,
          content_type: content_type,
          identify: false # Skip image processing during migration
        )

        # Verify attachment was successful
        unless record.send(attachment_name).attached?
          puts "\n  [ERROR] Failed to attach file: #{model_class.name}##{record.id}"
          stats[:failed] += 1
          next
        end

        # Update blob metadata with checksum
        blob = record.send(attachment_name).blob
        blob.update(checksum: checksum)

        # Verify file size matches
        if blob.byte_size != file_size
          puts "\n  [WARN] File size mismatch: #{model_class.name}##{record.id}"
          puts "    Expected: #{file_size}, Got: #{blob.byte_size}"
        end

        stats[:success] += 1
        print '.' if stats[:success] % 10 == 0
      rescue StandardError => e
        puts "\n  [ERROR] Failed to migrate #{model_class.name}##{record.id}: #{e.message}"
        puts "    #{e.backtrace.first(3).join("\n    ")}"
        stats[:failed] += 1
      end
    end

    puts "\n  #{model_class.name}: #{stats[:success]}/#{stats[:total]} migrated, #{stats[:skipped]} skipped, #{stats[:failed]} failed"
  end

  def build_paperclip_path(model_class, attachment_name)
    case model_class.name
    when 'Task'
      "#{ENV.fetch('S3_PATH', '')}schools/:school/courses/:course/tasks/:id/:filename"
    when 'ScreenShot'
      "#{ENV.fetch('S3_PATH', '')}screen_shots/:id/:filename"
    when 'Group'
      "#{ENV.fetch('S3_PATH', '')}schools/:school/courses/:course/group/:id/:filename"
    when 'Game'
      "#{ENV.fetch('S3_PATH', '')}games/:id/:filename"
    when 'Course'
      "#{ENV.fetch('S3_PATH', '')}schools/:school/courses/:id/:filename"
    when 'BadgeImage'
      "#{ENV.fetch('S3_PATH', '')}games/:id/:filename"
    when 'Attachment'
      "#{ENV.fetch('S3_PATH', '')}schools/:school/files/:target/:target_id/:filename"
    else
      ':filename'
    end
  end

  def interpolate_path(record, path_template, attachment_name)
    path = path_template.dup

    # Replace interpolations with actual values
    path.gsub!(':school', record.school_id.to_s) if record.respond_to?(:school_id)
    path.gsub!(':course', record.course_id.to_s) if record.respond_to?(:course_id)
    path.gsub!(':id', record.id.to_s)
    path.gsub!(':target_id', record.target_id.to_s) if record.respond_to?(:target_id)
    path.gsub!(':target', record.target_type.to_s) if record.respond_to?(:target_type)
    path.gsub!(':filename', record.send("#{attachment_name}_file_name"))

    # Remove any remaining interpolations
    path.gsub!(/:[a-z_]+/, '')

    path
  end

  def calculate_checksum(file_path)
    Digest::MD5.base64digest(File.read(file_path))
  end

  def determine_content_type(filename)
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
