# sec_edgar_balance_sheet_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'
require 'sec_edgar_financial_statement_shared' # shared examples foor SecEdgar::FinancialStatement

describe SecEdgar::BalanceSheet do

  let(:create_fin_stmt) {

    @bogus_filename = "testvectors/file_that_doesnt_exist.html"
    @filename = "testvectors/2010_03_31.html"

    @fin_stmt = SecEdgar::BalanceSheet.new

  }

  it_should_behave_like 'SecEdgar::FinancialStatement'

end
  
