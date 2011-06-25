# sec_edgar_balance_sheet_spec.rb

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'sec_edgar'
require 'sec_edgar_financial_statement_shared' # shared examples foor SecEdgar::FinancialStatement

describe SecEdgar::BalanceSheet do

  let(:create_fin_stmt) {

    @bogus_filename = "/tmp/ao0gqq34q34g"

    # load a primary one
    @good_filename = "specs/testvectors/google/2010_03_31.html"

    @tenq = SecEdgar::QuarterlyReport.new 
    @tenq.log = Logger.new('sec_edgar.log')
    @tenq.log.level = Logger::DEBUG
    @tenq.parse(@good_filename);

    @fin_stmt = @tenq.bal_sheet

    # load a second one (to test merging, etc)
    @good_filename2 = "specs/testvectors/google/2011_03_31.html"

    @tenq2 = SecEdgar::QuarterlyReport.new
    @tenq2.log = Logger.new('sec_edgar.log')
    @tenq2.log.level = Logger::DEBUG
    @tenq2.parse(@good_filename2);

    @fin_stmt2 = @tenq2.bal_sheet
  }

  it_should_behave_like 'SecEdgar::FinancialStatement'

  ##############################################################################
  # Basic (as stated) arrays
  ##############################################################################

  describe "#assets" do
    it "FIXME" do
    end
  end

  describe "#liabs" do
    it "FIXME" do
    end
  end

  describe "#equity" do
    it "FIXME" do
    end
  end

  ##############################################################################
  # Basic (as stated) totals
  ##############################################################################

  describe "#total_assets" do
    it "returns the total value of assets" do
      create_fin_stmt
      reporting_period = 1

      sum = 0.0
      @fin_stmt.assets.each do |a|
        if not a[reporting_period].val.nil?
          sum += a[reporting_period].val
        end
      end
      @fin_stmt.total_assets[reporting_period].should == sum
    end
  end

  describe "#total_liabs" do
    it "returns the total value of liabilities" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.liabs.each do |l|
        if not l[reporting_period].val.nil?
          sum += l[reporting_period].val
        end
      end
      @fin_stmt.total_liabs[reporting_period].should == sum
    end
  end

  describe "#total_equity" do
    it "returns the total value of equity" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.equity.each do |e|
        if not e[reporting_period].val.nil?
          sum += e[reporting_period].val
        end
      end
      @fin_stmt.total_equity[reporting_period].should == sum
    end
  end

  ##############################################################################
  # Restated arrays
  ##############################################################################

  describe "#operational_assets" do
    it "contains all assets that aren't in financial_assets" do
      a  = @fin_stmt.assets.collect { |x| x[0].text }
      oa = @fin_stmt.operational_assets.collect { |x| x[0].text }
      fa = @fin_stmt.financial_assets.collect { |x| x[0].text }
      oa.sort.should == (a - fa).sort
    end
  end

  describe "#financial_assets" do
    it "FIXME" do
    end
  end

  describe "#operational_liabs" do
    it "contains all liabilities that aren't in financial_liabs" do
      reporting_period = 1

      l  = @fin_stmt.liabs.collect { |x| x[0].text }
      ol = @fin_stmt.operational_liabs.collect { |x| x[0].text }
      fl = @fin_stmt.financial_liabs.collect { |x| x[0].text }
      ol.sort.should == (l - fl).sort
    end
  end

  describe "#financial_liabs" do
    it "shouldn't contain any common equity" do
      @fin_stmt.common_equity.each do |e|
        e[0].text.downcase.should_not match /common stock/
      end
    end

  end

  describe "#common_equity" do
    it "contains only common (vs. preferred) equity" do
      @ec = SecEdgar::EquityClassifier.new
      @fin_stmt.common_equity.each do |e|
        @ec.classify(e[0].text)[:class].should == :cse
        e[0].text.should_not match /preferred/
      end
    end
  end

  ##############################################################################
  # Restated totals
  ##############################################################################

  describe "#total_oa" do
    it "returns the sum of the operational assets" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.operational_assets.each do |x|
        if not x[reporting_period].val.nil?
          sum += x[reporting_period].val
        end
      end
      @fin_stmt.total_oa[reporting_period].should == sum
    end
  end

  describe "#total_fa" do
    it "returns the sum of the financial assets" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.financial_assets.each do |x|
        if not x[reporting_period].val.nil?
          sum += x[reporting_period].val
        end
      end
      @fin_stmt.total_fa[reporting_period].should == sum
    end
  end

  describe "#total_ol" do
    it "returns the sum of the operational liabilities" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.operational_liabs.each do |x|
        if not x[reporting_period].val.nil?
          sum += x[reporting_period].val
        end
      end
      @fin_stmt.total_ol[reporting_period].should == sum
    end
  end

  describe "#total_fl" do
    it "returns the sum of the financial liabilities" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.financial_liabs.each do |x|
        if not x[reporting_period].val.nil?
          sum += x[reporting_period].val
        end
      end
      @fin_stmt.total_fl[reporting_period].should == sum
    end
  end

  describe "#noa" do
    it "returns operational assets minus operational liabilities" do
      reporting_period = 1

      diff = @fin_stmt.total_oa[reporting_period] - @fin_stmt.total_ol[reporting_period]
      @fin_stmt.noa[reporting_period].should == diff
    end
  end

  describe "#nfa" do
    it "returns financial assets minus financial liabilities" do
      reporting_period = 1

      diff = @fin_stmt.total_fa[reporting_period] - @fin_stmt.total_fl[reporting_period]
      @fin_stmt.nfa[reporting_period].should == diff
    end
  end

  describe "#cse" do
    it "returns the sum of common_equity" do
      reporting_period = 1

      sum = 0.0
      @fin_stmt.common_equity.each do |e|
        if not e[reporting_period].val.nil?
          sum += e[reporting_period].val
        end
      end
      @fin_stmt.cse[reporting_period].should == sum
    end
    it "is equal to nfa plus noa" do
      reporting_period = 1

      sum = @fin_stmt.noa[reporting_period] + @fin_stmt.nfa[reporting_period]
      @fin_stmt.cse[reporting_period].should == sum
    end
  end

end
 
