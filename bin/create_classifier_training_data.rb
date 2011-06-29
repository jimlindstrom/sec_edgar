#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

#@tickers = ['YHOO','INTC','CSCO','ORCL','WMT','SAP','PFE','LLY','XOM','INTU','F','AA','MSFT','CRM','GOOG']
@tickers = [       'INTC','CSCO','ORCL','WMT','SAP','PFE','LLY','XOM','INTU','F','AA','MSFT','CRM','GOOG'] # YHOO was causing too many issues

@filenames = []

@ignored_filenames =
  [  "/Users/jimlindstrom/code/sec_edgar/pagecache/a91a2ae11eb35a312970a6164d89f021270adc4a.html",  # Yahoo 10-Q 2005-03-31 (indented TDs)
     "/Users/jimlindstrom/code/sec_edgar/pagecache/df393ea58c8ab713b5382ef74c3726a734d67be7.html",  # Yahoo 10-Q 2003-09-30 (indented TDs)
     "/Users/jimlindstrom/code/sec_edgar/pagecache/897545ce051bdeeab4a4bbd255f19a6f104de291.html",  # Yahoo 10-Q 2002-06-30 (indented TDs)
     "/Users/jimlindstrom/code/sec_edgar/pagecache/8f978e6e441056bc1b4ee132661a7538ffdd702c.html",  # Yahoo 10-Q 2002-03-31 (indented TDs)
     "/Users/jimlindstrom/code/sec_edgar/pagecache/8b97f8e30adeded7230fe875e320f2ec036a9c14.html",  # Yahoo 10-Q 2001-06-30 (indented TDs)
     "/Users/jimlindstrom/code/sec_edgar/pagecache/e347dbec00f32af33981dc8beb390480ed2c8356.html"]  # Intel 10-Q 2002-09-28 (not sure yet)

@liabs = []
@assets = []
@equity = []

@log = Logger.new('sec_edgar.log')
@log.level = Logger::DEBUG

@download_path = "/tmp/"
@tickers.each do |ticker|
  puts "Downloading 10q's for #{ticker}"
  @edgar = SecEdgar::Edgar.new
  @edgar.log = @log
  @filenames.concat(@edgar.download_10q_reports(ticker, @download_path))
end

@filenames.each do |filename|
  if @ignored_filenames.include?(filename)
    # there are some files that we just can't parse yet...
  else
    puts "Parsing #{filename}"
    begin
      @tenq = SecEdgar::QuarterlyReport.new
      @tenq.log = @log
      ret = @tenq.parse(filename)
      raise "parse fail" if ret == false
      @fin_stmt = @tenq.bal_sheet
      raise "parse fail" if @fin_stmt.nil?
    
      @liabs.concat(@fin_stmt.liabs)
      @assets.concat(@fin_stmt.assets)
      @equity.concat(@fin_stmt.equity)
    rescue SecEdgar::ParseError
      puts "couldn't parse. skipping."
    end
  end
end

fh = File.new("classifier_training/assets_training.txt", "w")
@asset_labels = @assets.collect do |x| 
  if !x.nil? and !x.label.nil?
    x.label.downcase    
  else
    ""
  end
end
@asset_labels.each { |a| fh.puts(a) }
fh.close

fh = File.new("classifier_training/liabs_training.txt", "w")
@liab_labels = @liabs.collect do |x| 
  if !x.nil? and !x.label.nil?
    x.label.downcase    
  else
    ""
  end
end
@liab_labels.each { |l| fh.puts(l) }
fh.close

fh = File.new("classifier_training/equity_training.txt", "w")
@equity_labels = @equity.collect do |x| 
  if !x.nil? and !x.label.nil?
    x.label.downcase    
  else
    ""
  end
end
@equity_labels.each { |l| fh.puts(l) }
fh.close
