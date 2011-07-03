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
  #end

end

describe SecEdgar::QuarterlyReport do

  it_should_behave_like '#parse', "specs/testvectors/apple/2010_03_27.html"
  it_should_behave_like '#parse', "specs/testvectors/deere/2004_01_31.html"
  it_should_behave_like '#parse', "specs/testvectors/google/2009_09_30.html"
  it_should_behave_like '#parse', "specs/testvectors/intel/2005_07_02.html"
  it_should_behave_like '#parse', "specs/testvectors/microsoft/2011_03_31.html"

  context "when base multiplier precedes the IS or BS table" do
    it "parses the base multiplier (ABTL)" do
      filename="/Users/jimlindstrom/code/sec_edgar/pagecache/bc6111eea4338ddabf688d960ee74baea08a5499.html"

      @tenq = SecEdgar::QuarterlyReport.new
      @tenq.log = Logger.new('sec_edgar.log')
      @tenq.log.level = Logger::DEBUG
      @tenq.parse(filename)
      @tenq.inc_stmt.base_multiplier.should == 1000
    end

    it "parses the base multiplier (ACXM)" do
      filename="/Users/jimlindstrom/code/sec_edgar/pagecache/606be9ddfa63e0862e82f7cadb06d493eaea628d.html"

      @tenq = SecEdgar::QuarterlyReport.new
      @tenq.log = Logger.new('sec_edgar.log')
      @tenq.log.level = Logger::DEBUG
      @tenq.parse(filename)
      @tenq.bal_sheet.base_multiplier.should == 1000
    end

    it "parses the base multiplier (ATVI)" do
      filename="/Users/jimlindstrom/code/sec_edgar/pagecache/174bc2ede6393b09e3ffa7bacad6810139a371fa.html"

      @tenq = SecEdgar::QuarterlyReport.new
      @tenq.log = Logger.new('sec_edgar.log')
      @tenq.log.level = Logger::DEBUG
      @tenq.parse(filename)
      @tenq.bal_sheet.base_multiplier.should == 1000
    end
  end

  context "when base multiplier is not given" do
    it "assumes a base multiplier of one (ACY)" do
      filename="/Users/jimlindstrom/code/sec_edgar/pagecache/94c7feb1f3b3541300f06f47b1ddcc2b17856b52.html" 

      @tenq = SecEdgar::QuarterlyReport.new
      @tenq.log = Logger.new('sec_edgar.log')
      @tenq.log.level = Logger::DEBUG
      @tenq.parse(filename)
      @tenq.inc_stmt.base_multiplier.should == 1
    end

    it "assumes a base multiplier of one (ALOT)" do
      filename="/Users/jimlindstrom/code/sec_edgar/pagecache/8e4fa9c2610fcb4342736ed5db17ce7226dfade2.html"

      @tenq = SecEdgar::QuarterlyReport.new
      @tenq.log = Logger.new('sec_edgar.log')
      @tenq.log.level = Logger::DEBUG
      @tenq.parse(filename)
      @tenq.inc_stmt.base_multiplier.should == 1
    end
  end

end

