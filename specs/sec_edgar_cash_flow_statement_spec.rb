# sec_edgar_cash_flow_statement_spec.rb

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'sec_edgar'
require 'sec_edgar_financial_statement_shared' # shared examples foor SecEdgar::FinancialStatement

describe SecEdgar::CashFlowStatement do

  let(:create_fin_stmt) do

    @bogus_filename = "/tmp/ao0gqq34q34g"

    # load a primary one
    @good_filename = "specs/testvectors/2010_03_31.html"

    @tenq = SecEdgar::QuarterlyReport.new
    @tenq.parse(@good_filename)

    @fin_stmt = @tenq.cash_flow_stmt

    # load a second one (to test merging, etc)
    @good_filename2 = "specs/testvectors/2011_03_31.html"

    @tenq2 = SecEdgar::QuarterlyReport.new
    @tenq2.parse(@good_filename2)

    @fin_stmt2 = @tenq2.cash_flow_stmt
  end

  it_should_behave_like 'SecEdgar::FinancialStatement'

end
 
