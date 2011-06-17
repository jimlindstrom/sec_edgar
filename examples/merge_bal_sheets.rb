#!/usr/bin/env ruby

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'rubygems'
require 'sec_edgar'

# load a primary one
@good_filename = "specs/testvectors/2010_03_31.html"

@tenq = SecEdgar::QuarterlyReport.new
@tenq.parse(@good_filename)
@tenq.normalize

@fin_stmt = @tenq.bal_sheet
@fin_stmt.write_to_csv("1.csv")

# load a second one (to test merging, etc)
@good_filename2 = "specs/testvectors/2011_03_31.html"

@tenq2 = SecEdgar::QuarterlyReport.new
@tenq2.parse(@good_filename2)
@tenq2.normalize

@fin_stmt2 = @tenq2.bal_sheet
@fin_stmt2.write_to_csv("2.csv")

@fin_stmt.merge(@fin_stmt2)

@fin_stmt.write_to_csv("merged.csv")
