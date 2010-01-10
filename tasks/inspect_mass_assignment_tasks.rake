desc "Inspect all ActiveRecord models regarding mass-assignment"
task :inspect_mass_assignment => :environment do
  if ActiveSupport::Dependencies.mechanism == :load
    puts "\nERROR: inspect_mass_assignment needs config.cache_classes=true"
    puts "For instance try the test environment: rake inspect_mass_assignment RAILS_ENV=test"
  else
    # Obviously the application classes are not loaded by Rails in case of rake tasks
    # So we have to require all of them manually
    # Slightly related issue: https://rails.lighthouseapp.com/projects/8994/tickets/2506-models-are-not-loaded-in-migrations-when-configthreadsafe-is-set  
    Dir["#{File.expand_path(RAILS_ROOT) + "/app/models"}/**/*.rb"].each do |f|
      #puts f
      require f
    end
    
    html =  InspectMassAssignment.inspect_activerecord
    file = File.new("inspect_mass_assignment.html", "w")
    file.write(html)
    
    puts "\n\nResult written to inspect_mass_assignment.html"
  
    begin
      require 'launchy'
      Launchy::Browser.run(file.path)
    rescue
      puts "HINT: Install launchy gem to automatically load the file in the browser: sudo gem install launchy"
    end
  end  
end
