#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

@tickers = ['MSFT','CRM','GOOG','YHOO','INTC','CSCO','ORCL','WMT','SAP','PFE','LLY','XOM','INTU','F','AA']

@filenames = []

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
  puts "Parsing #{filename}"
  @tenq = SecEdgar::QuarterlyReport.new
  @tenq.log = @log
  ret = @tenq.parse(filename)
  raise "parse fail" if ret == false
  @fin_stmt = @tenq.bal_sheet
  raise "parse fail" if @fin_stmt.nil?

  @liabs.concat(@fin_stmt.liabs)
  @assets.concat(@fin_stmt.assets)
  @equity.concat(@fin_stmt.equity)
end

fh = File.new("classifier_training/assets_training.txt", "w")
@asset_labels = @assets.collect { |x| x[0].text.downcase }
@asset_labels.each { |a| fh.puts(a) }
fh.close

fh = File.new("classifier_training/liabs_training.txt", "w")
@liab_labels = @liabs.collect { |x| x[0].text.downcase }
@liab_labels.each { |l| fh.puts(l) }
fh.close

fh = File.new("classifier_training/equity_training.txt", "w")
@equity_labels = @equity.collect { |x| x[0].text.downcase }
@equity_labels.each { |l| fh.puts(l) }
fh.close
