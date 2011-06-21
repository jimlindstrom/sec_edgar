#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

@tenq = SecEdgar::QuarterlyReport.new
@tenq.parse("/tmp/2011_03_31.html")
@fin_stmt = @tenq.bal_sheet
puts "operational assets #1: #{@fin_stmt.operational_assets(1)}"
puts "operational assets #2: #{@fin_stmt.operational_assets(2)}"

puts "financial assets #1: #{@fin_stmt.financial_assets(1)}"
puts "financial assets #2: #{@fin_stmt.financial_assets(2)}"

puts "calc total assets #1: #{@fin_stmt.calculated_total_assets(1)}"
puts "calc total assets #2: #{@fin_stmt.calculated_total_assets(2)}"
