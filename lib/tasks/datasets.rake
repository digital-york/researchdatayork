namespace :datasets do

  # refresh datasets with pure data from the last x days
  task :refresh, [:days] => :environment do |t, args|
    begin
      puts '========= ' + DateTime.now.to_s + ' ========'
      refreshed = DepositsController.new.refresh_from_pure(nil, args[:days])
      puts 'Refreshed ' + refreshed.size.to_s + ' record(s)'
      puts refreshed
    rescue => e
      puts "Error!"
      puts e.message
    end
  end
end
