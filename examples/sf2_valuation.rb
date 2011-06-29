#!/usr/bin/env ruby

require 'yaml'
$LOAD_PATH << './lib'
require 'sec_edgar'

data = YAML::load( File.open( ARGV[0] ) )
puts "doing SF2 valuation for #{data['ticker']}"

# get the financial summary (from all historical 10k's)
summary = SecEdgar::Helpers.get_all_10ks(data["ticker"])

# calculate cost of capital
tax_rate = 0.35
rho_e = 1.0 + SecEdgar::Helpers.equity_cost_of_capital__capm(SecEdgar::Helpers::RISK_FREE_RATE, 
                                                             SecEdgar::Helpers::EXPECTED_RETURN_FOR_EQUITIES, 
                                                             data["beta"])
rho_d = 1.04 # decent average to work with
rho_f = SecEdgar::Helpers.weighted_avg_cost_of_capital(data["ticker"], summary, rho_e, rho_d, tax_rate)

# perform valuation
shares_outstanding = SecEdgar::Helpers.get_shares_outstanding(data["ticker"]) 
v_cse_share_0 = summary.sf2_valuation(data["forecast_data"], rho_f, shares_outstanding / 1000.0)

puts "            ticker: #{data['ticker']}"
puts "shares outstanding: #{shares_outstanding}"
puts "             rho_f: #{rho_f}"
puts "   value per share: #{v_cse_share_0}"
summary.to_csv("summary.csv")
