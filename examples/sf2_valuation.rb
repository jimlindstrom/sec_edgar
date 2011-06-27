#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

ticker = 'GOOG'
beta = 1.15
forecast_data = 
  [ { :revenue_growth => 0.25, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.50 },
    { :revenue_growth => 0.20, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.20 },
    { :revenue_growth => 0.15, :sales_pm => 0.17, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.10, :sales_pm => 0.16, :fi_over_nfa => 0.01, :ato => 0.90 },
    { :revenue_growth => 0.04, :sales_pm => 0.15, :fi_over_nfa => 0.01, :ato => 0.90 } ]


summary = SecEdgar::Helpers.get_all_10ks(ticker)

rho_f = 1.0 + SecEdgar::Helpers.wacc_capm(SecEdgar::Helpers::RISK_FREE_RATE, SecEdgar::Helpers::EQUITY_RISK_PREMIUM, beta)
shares_outstanding = SecEdgar::Helpers.get_shares_outstanding(ticker) 

v_cse_share_0 = summary.sf2_valuation(forecast_data, rho_f, shares_outstanding / 1000.0)

puts "shares outstanding: #{shares_outstanding}"
puts "             rho_f: #{rho_f}"
puts "   value per share: #{v_cse_share_0}"
summary.to_csv("summary.csv")
