namespace :test do
  desc "Runs all specs"
  task :specs do
    sh "rspec -c specs/"
  end

  desc "Runs the 10-K parser against a the Nasdaq tech companies to see what fraction pass"
  task :n_tickers, :num_tests do |t, args|
    num_tests=args[:num_tests]
    if num_tests.nil? or Integer(num_tests) < 1
      raise "must specify the number of tests to run"
    end

    sh "./bin/create_specs_for_all_nasdaq_tech.rb #{num_tests}"
    out_file = "/tmp/ag083t01304g8h1g430j134j"
    sh "if [ -f sec_edgar.log ]; then rm sec_edgar.log; fi"
    sh "rspec -c -fd /tmp/sec_edgar_parsing_spec.rb | tee #{out_file}"

    puts "\nMost common failures:"
    sh "grep -a2 SecEdgar::Parse #{out_file} | grep '#' | sort | uniq -c | sort -n"
  end

  desc "Runs the 10-K parser against a single ticker"
  task :single_ticker, :ticker do |t, args|
    ticker=args[:ticker]
    if ticker.nil? 
      raise "must specify the company to run against" 
    end

    sh "./bin/create_specs_for_single_company.rb #{ticker}"
    sh "if [ -f sec_edgar.log ]; then rm sec_edgar.log; fi"
    sh "rspec -c -fd /tmp/sec_edgar_parsing_spec.rb"
  end

end

namespace :cache do

  desc "Removes all downloaded reports from the page cache"
  task :clean do
    sh "rm pagecache/*"
    sh "rm indexcache/*"
  end

end

