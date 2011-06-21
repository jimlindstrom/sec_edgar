#!/usr/bin/env ruby

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'sec_edgar'

@tickers = ['CRM','MSFT','GOOG','YHOO','INTC']
@download_path = "/tmp/"

@liabs = []
@assets = []

@tickers.each do |cur_ticker|
  puts "Parsing #{cur_ticker}"
  @edgar = SecEdgar::Edgar.new
  @filenames = @edgar.download_10q_reports(cur_ticker, @download_path)

  @tenq = SecEdgar::QuarterlyReport.new
  ret = @tenq.parse(@filenames.first) 
  #raise "parse fail" if ret == false
  @fin_stmt = @tenq.bal_sheet
  raise "parse fail" if @fin_stmt.nil?

  @liabs.concat(@fin_stmt.liabs)
  @assets.concat(@fin_stmt.assets)
end

fh = File.new("classifier_training/assets_training.txt", "w")
@asset_labels = @assets.collect { |x| x[0].text.downcase }
@asset_labels.each { |a| fh.puts(a) }
fh.close

fh = File.new("classifier_training/liabs_training.txt", "w")
@liab_labels = @liabs.collect { |x| x[0].text.downcase }
@liab_labels.each { |l| fh.puts(l) }
fh.close
