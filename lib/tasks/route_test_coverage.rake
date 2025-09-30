namespace :levelfly do
  desc 'Checks whether each route has a corresponding rspec request spec'
  task route_test_coverage: :environment do
    spec_files = Dir['spec/requests/*.rb']

    counts = { missing: 0, found: 0 }

    verbose = ENV.fetch('VERBOSE', '0') == 1

    missing_routes = []

    Rails.application.routes.routes.to_a.each do |route|
      controller = route.defaults[:controller]
      action = route.defaults[:action]

      next if controller.nil? || controller.include?('/')

      found = spec_files.any? do |spec_file|
        !File.foreach(spec_file).grep(/url_for.*#{controller}.*:#{action}[^a-z]/).empty?
      end

      if found
        puts "Found #{controller}##{action}" if verbose
        counts[:found] += 1
      else
        puts "#{controller}##{action} missing" if verbose
        counts[:missing] += 1
        missing_routes << "#{controller}##{action}"
      end
    end

    puts "Found #{counts.values.sum} routes:"
    puts "* Tested: #{counts[:found]}"
    puts "* Missing: #{counts[:missing]}"
    puts
    puts 'Missing routes:'
    puts missing_routes.uniq.sort!
  end
end
