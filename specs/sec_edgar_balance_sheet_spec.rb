# sec_edgar_balance_sheet_spec.rb

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'sec_edgar'
require 'sec_edgar_financial_statement_shared' # shared examples foor SecEdgar::FinancialStatement

describe SecEdgar::BalanceSheet do

  let(:create_fin_stmt) {

    @bogus_filename = "/tmp/ao0gqq34q34g"

    # load a primary one
    @good_filename = "specs/testvectors/2010_03_31.html"

    @tenq = SecEdgar::QuarterlyReport.new
    @tenq.parse(@good_filename)
    @tenq.normalize

    @fin_stmt = @tenq.bal_sheet

    # load a second one (to test merging, etc)
    @good_filename2 = "specs/testvectors/2011_03_31.html"

    @tenq2 = SecEdgar::QuarterlyReport.new
    @tenq2.parse(@good_filename2)
    @tenq2.normalize

    @fin_stmt2 = @tenq2.bal_sheet
  }

  it_should_behave_like 'SecEdgar::FinancialStatement'

end
 
