desc 'Check for vulnerabilities in Ruby gems'
task :gemsurance do
  require 'gemsurance'
  gem_infos = Gemsurance::Runner.new.run.tap { |r| r.send(:generate_report) }.gem_infos
  if gem_infos.any? { |info| info.vulnerable? }
    raise("One or more of your Ruby gems has a known security vulnerability. Check #{Rails.root}/gemsurance_report.html for more info.")
  end
end