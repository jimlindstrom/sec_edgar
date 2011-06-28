#require 'bundler/gem_tasks'


desc "Runs all specs"
task :test do
  sh "rspec -c specs/"
end

namespace :cache do

  desc "Removes all files from the page cache"
  task :clean do
    sh "rm pagecache/*"
  end

end

