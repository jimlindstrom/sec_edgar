#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'sec_edgar'

# set up the valuation with forecast data
ticker = 'GOOG'
beta = 1.15
forecast_data = 
  [ { :revenue_growth => 0.25, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.50 },
    { :revenue_growth => 0.20, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.20 },
    { :revenue_growth => 0.15, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.10 },
    { :revenue_growth => 0.15, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.15, :sales_pm => 0.17, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.10, :sales_pm => 0.16, :fi_over_nfa => 0.01, :ato => 0.90 },
    { :revenue_growth => 0.04, :sales_pm => 0.15, :fi_over_nfa => 0.01, :ato => 0.90 } ]

# set up the valuation with forecast data
ticker = 'INTC'
beta = 1.12
forecast_data = 
  [ { :revenue_growth => 0.12, :sales_pm => 0.22, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.11, :sales_pm => 0.21, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.11, :sales_pm => 0.20, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.10, :sales_pm => 0.19, :fi_over_nfa => 0.01, :ato => 1.00 },
    { :revenue_growth => 0.04, :sales_pm => 0.17, :fi_over_nfa => 0.01, :ato => 1.00 } ]

# set up the valuation with forecast data
ticker = 'CRM'
beta = 1.22
forecast_data = 
  [ { :revenue_growth => 0.08, :sales_pm => 0.26, :fi_over_nfa => 0.00, :ato => 1.20 },
    { :revenue_growth => 0.07, :sales_pm => 0.25, :fi_over_nfa => 0.00, :ato => 1.15 },
    { :revenue_growth => 0.06, :sales_pm => 0.24, :fi_over_nfa => 0.00, :ato => 1.10 },
    { :revenue_growth => 0.05, :sales_pm => 0.20, :fi_over_nfa => 0.00, :ato => 1.05 },
    { :revenue_growth => 0.04, :sales_pm => 0.18, :fi_over_nfa => 0.00, :ato => 1.00 } ]

# set up the valuation with forecast data
ticker = 'MSFT'
beta = 1.05
forecast_data = 
  [ { :revenue_growth => 0.08, :sales_pm => 0.26, :fi_over_nfa => 0.00, :ato => 1.20 },
    { :revenue_growth => 0.07, :sales_pm => 0.25, :fi_over_nfa => 0.00, :ato => 1.15 },
    { :revenue_growth => 0.06, :sales_pm => 0.24, :fi_over_nfa => 0.00, :ato => 1.10 },
    { :revenue_growth => 0.05, :sales_pm => 0.20, :fi_over_nfa => 0.00, :ato => 1.05 },
    { :revenue_growth => 0.04, :sales_pm => 0.18, :fi_over_nfa => 0.00, :ato => 1.00 } ]


# get the financial summary (from all historical 10k's)
summary = SecEdgar::Helpers.get_all_10ks(ticker)

# calculate cost of capital
tax_rate = 0.35
rho_e = 1.0 + SecEdgar::Helpers.equity_cost_of_capital__capm(SecEdgar::Helpers::RISK_FREE_RATE, 
                                                             SecEdgar::Helpers::EXPECTED_RETURN_FOR_EQUITIES, 
                                                             beta)
rho_d = 1.04 # decent average to work with
rho_f = SecEdgar::Helpers.weighted_avg_cost_of_capital(ticker, summary, rho_e, rho_d, tax_rate)

# perform valuation
shares_outstanding = SecEdgar::Helpers.get_shares_outstanding(ticker) 
v_cse_share_0 = summary.sf2_valuation(forecast_data, rho_f, shares_outstanding / 1000.0)

puts "shares outstanding: #{shares_outstanding}"
puts "             rho_f: #{rho_f}"
puts "   value per share: #{v_cse_share_0}"
summary.to_csv("summary.csv")
