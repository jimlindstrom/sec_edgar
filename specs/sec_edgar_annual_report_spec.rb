# sec_edgar_annual_report_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

describe SecEdgar::AnnualReport do
  describe "#parse" do

  before(:each) do
    @bogus_filename = "/tmp/ao0gqq34q34g"
    @good_filename = "specs/testvectors/2010_12_31.html"
    @tenk = SecEdgar::AnnualReport.new
    @tenk.log = Logger.new('sec_edgar.log')
    @tenk.log.level = Logger::DEBUG
  end

  after(:each) do
    @tenk = nil
  end
   
    it "returns false if file doesn't exist or file doesn't contain annual report" do
      @tenk.parse(@bogus_filename).should == false
    end
    it "returns true if file exists and contains annual report" do
      @tenk.parse(@good_filename).should == true
    end
    it "creates a balance sheet if success" do
      @tenk.parse(@good_filename)
      @tenk.bal_sheet.class.should == SecEdgar::BalanceSheet
    end
    it "creates an income statement if success" do
      @tenk.parse(@good_filename)
      @tenk.inc_stmt.class.should == SecEdgar::IncomeStatement
    end
  end

end

