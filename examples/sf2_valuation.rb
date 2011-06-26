#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

ticker = 'GOOG'
rept_type = '10-K'
download_path = "/tmp/"
edgar = SecEdgar::Edgar.new

reports = edgar.lookup_reports(ticker)
reports.keep_if{ |r| r[:type] == rept_type }
reports.sort! {|a,b| a[:date] <=> b[:date] }

files = edgar.get_reports(reports, download_path)

ten_k = SecEdgar::AnnualReport.new 
ten_k.log = Logger.new('sec_edgar.log')
ten_k.log.level = Logger::DEBUG
ten_k.parse(files.shift)
summary = ten_k.get_summary
ten_k = nil

while !files.empty?
  ten_k2 = SecEdgar::AnnualReport.new 
  ten_k2.log = Logger.new('sec_edgar.log')
  ten_k2.log.level = Logger::DEBUG
  ten_k2.parse(files.shift)
  summary2 = ten_k2.get_summary

  summary.merge(summary2)
end


forecast_data = 
  [ { :revenue_growth => 0.15,
      :sales_pm       => 0.17,
      :fi_over_nfa    => 0.01,
      :ato            => 1.50 },
    { :revenue_growth => 0.15,
      :sales_pm       => 0.17,
      :fi_over_nfa    => 0.01,
      :ato            => 1.50 },
    { :revenue_growth => 0.15,
      :sales_pm       => 0.17,
      :fi_over_nfa    => 0.01,
      :ato            => 1.50 },
    { :revenue_growth => 0.15,
      :sales_pm       => 0.17,
      :fi_over_nfa    => 0.01,
      :ato            => 1.50 },
    { :revenue_growth => 0.04,
      :sales_pm       => 0.17,
      :fi_over_nfa    => 0.01,
      :ato            => 1.50 } ]

rho_f = 1.11
thousands_of_shares = 322250

v_cse_share_0 = summary.sf2_valuation(forecast_data, rho_f, thousands_of_shares)
puts "value per share = #{v_cse_share_0}"

summary.to_csv("summary.csv")
