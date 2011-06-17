#!/usr/bin/env ruby

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'rubygems'
require 'sec_edgar'

@ticker = 'GOOG'
@download_path = '/tmp/'

# get all the quarterly reports for Google
@edgar = SecEdgar::Edgar.new
exit if not @edgar.good_ticker?(@ticker)
@list_of_files = @edgar.download_10q_reports(@ticker, @download_path)

# load first balance sheet
@tenq = SecEdgar::QuarterlyReport.new
@tenq.parse(@list_of_files[0])
@tenq.normalize

# load second balance sheet
@tenq2 = SecEdgar::QuarterlyReport.new
@tenq2.parse(@list_of_files[1])
@tenq2.normalize

# merge and write
@fin_stmt = @tenq.bal_sheet
@fin_stmt2 = @tenq2.bal_sheet
@fin_stmt.merge(@fin_stmt2)
@fin_stmt.write_to_csv("merged.csv")
