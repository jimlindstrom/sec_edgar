#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

@companies = 
  [{:ticker=>'GOOG', :download_path=>"specs/testvectors/google/"},
  {:ticker=>'AAPL', :download_path=>"specs/testvectors/apple/"},
  {:ticker=>'INTC', :download_path=>"specs/testvectors/intel/"},
  {:ticker=>'IBM', :download_path=>"specs/testvectors/ibm/"},
  {:ticker=>'MSFT', :download_path=>"specs/testvectors/microsoft/"},
  {:ticker=>'DE', :download_path=>"specs/testvectors/deere/"}]

@edgar = SecEdgar::Edgar.new
@edgar.log = Logger.new('sec_edgar.log')
@edgar.log.level = Logger::INFO
@companies.each do |company|
  puts "getting 10q's for #{company[:ticker]}"
  @edgar.download_10q_reports(company[:ticker], company[:download_path])

  puts "getting 10k's for #{company[:ticker]}"
  @edgar.download_10k_reports(company[:ticker], company[:download_path])
end

