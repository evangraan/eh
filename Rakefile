task :default => :test

desc "Test SMAAK protocol"
task :test do
  sh %{bundle install}
  sh %{bundle exec rspec -cfd spec}
end
