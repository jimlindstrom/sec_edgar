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
    @tenq.parse(@good_filename);

    @fin_stmt = @tenq.bal_sheet

    # load a second one (to test merging, etc)
    @good_filename2 = "specs/testvectors/2011_03_31.html"

    @tenq2 = SecEdgar::QuarterlyReport.new
    @tenq2.parse(@good_filename2);

    @fin_stmt2 = @tenq2.bal_sheet
  }

  it_should_behave_like 'SecEdgar::FinancialStatement'

  describe "#calculated_total_assets" do
    it "returns the same amount as the \"total assets\" line in the balance sheet (1st reporting period)" do
      @fin_stmt.calculated_total_assets(1).should == @fin_stmt.total_assets[1].val
    end
    it "returns the same amount as the \"total assets\" line in the balance sheet (2nd reporting period)" do
      @fin_stmt.calculated_total_assets(2).should == @fin_stmt.total_assets[2].val
    end
  end

  describe "#operational_assets" do
    it "returns the amount of the company's assets that are operational (1st reporting period)" do
      @fin_stmt.operational_assets(1).should == @fin_stmt.calculated_total_assets(1) - @fin_stmt.financial_assets(1)
    end
    it "returns the amount of the company's assets that are operational (2nd reporting period)" do
      @fin_stmt.operational_assets(2).should == @fin_stmt.calculated_total_assets(2) - @fin_stmt.financial_assets(2)
    end
  end

end
 
