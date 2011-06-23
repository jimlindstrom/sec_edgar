# sec_edgar_quarterly_report_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

shared_examples_for '#parse' do |filename|

  before(:each) do
    @bogus_filename = "/tmp/ao0gqq34q34g"
    @good_filename = filename
    @tenq = SecEdgar::QuarterlyReport.new
    @tenq.log = Logger.new('sec_edgar.log')
    @tenq.log.level = Logger::DEBUG
  end
   
  #describe "#parse" do
    it "returns false if file doesn't exist or file doesn't contain quarterly report (#{filename})" do
      @tenq.parse(@bogus_filename).should == false
    end
    it "returns true if file exists and contains quarterly report (#{filename})" do
      @tenq.parse(@good_filename).should == true
    end
    it "creates a balance sheet if success (#{filename})" do
      @tenq.parse(@good_filename)
      @tenq.bal_sheet.class.should == SecEdgar::BalanceSheet
    end
    it "creates an income statement if success (#{filename})" do
      @tenq.parse(@good_filename)
      @tenq.inc_stmt.class.should == SecEdgar::IncomeStatement
    end
    it "creates a cash flow statement if success (#{filename})" do
      @tenq.parse(@good_filename)
      @tenq.cash_flow_stmt.class.should == SecEdgar::CashFlowStatement
    end
  #end

end

describe SecEdgar::QuarterlyReport do

  it_should_behave_like '#parse', "specs/testvectors/apple/2010_03_27.html"
  it_should_behave_like '#parse', "specs/testvectors/deere/2004_01_31.html"
  it_should_behave_like '#parse', "specs/testvectors/google/2009_09_30.html"
  it_should_behave_like '#parse', "specs/testvectors/intel/2005_07_02.html"
  it_should_behave_like '#parse', "specs/testvectors/microsoft/2011_03_31.html"

end

