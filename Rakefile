#require 'bundler/gem_tasks'


desc "Runs all specs"
task :test do
  sh "rspec -c specs/"
end

namespace :test do

  desc "Runs the 10-K parser against a the Nasdaq tech companies to see what fraction pass"
  task :all, :num_tests do |t, args|
    num_tests=args[:num_tests]
    if num_tests.nil? or Integer(num_tests) < 1
      raise "must specify the number of tests to run"
    end

    sh "./bin/create_specs_for_all_nasdaq_tech.rb #{num_tests}"
    out_file = "/tmp/ag083t01304g8h1g430j134j"
    sh "rspec -c -fd /tmp/sec_edgar_parsing_spec.rb | tee #{out_file}"

    puts "\nMost common failures:"
    sh "grep -a2 SecEdgar::Parse #{out_file} | grep '#' | sort | uniq -c | sort -n"
  end

end


namespace :cache do

  desc "Removes all files from the page cache"
  task :clean do
    sh "rm pagecache/*"
  end

end

