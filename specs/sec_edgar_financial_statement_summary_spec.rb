# sec_edgar_financial_statement_summary_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

describe SecEdgar::FinancialStatementSummary do

  before(:each) do
  end
   
  describe "#simple_valuation" do
    it "returns a simple valuation of the common equity" do
      ticker = 'GOOG'
      rept_type = '10-K'
      download_path = "/tmp/"
      edgar = SecEdgar::Edgar.new
      
      reports = edgar.lookup_reports(ticker)
      reports.keep_if{ |r| r[:type] == rept_type }
      reports.sort! {|a,b| a[:date] <=> b[:date] }
      
      reports.keep_if{ |r| r[:date] =~ /2010/ }
      
      files = edgar.get_reports(reports, download_path)
      
      ten_k = SecEdgar::AnnualReport.new 
      ten_k.parse(files.first)
      
      summary = ten_k.get_summary
      
      g_1        = 1.15
      g_2        = 1.10
      g_long     = 1.04
      rho_f      = 1.10
      num_shares = 322250.0
      per_share_valuation = summary.simple_valuation(g_1, g_2, g_long, rho_f) / num_shares

      per_share_valuation.should be_within(0.1).of(521.1)
    end
  end
    
end

