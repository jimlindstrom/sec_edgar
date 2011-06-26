# sec_edgar_income_statement_spec.rb

$LOAD_PATH << './lib'
$LOAD_PATH << './specs'
require 'sec_edgar'
require 'sec_edgar_financial_statement_shared' # shared examples foor SecEdgar::FinancialStatement

describe SecEdgar::IncomeStatement do

  before(:all) do
    @vectors = 
      [ { :filename => "specs/testvectors/apple/2010_03_27.html", 
          :date0 => "2010",
          :date1 => "2009",
          :date2 => "2010",
          :date3 => "2009",
          :operating_revenue => 13499.0,
          :cost_of_revenue => 7874.0,
          :operating_expense => 1646.0,
          :operating_income_from_sales_before_tax => 3979.0,
          :other_operating_income_before_tax => 50.0,
          :operating_income_before_tax => 4029.0,
          :provision_for_tax => 955.0,
          :other_income_after_tax => 0.0,
          :net_income => 3074.0,
          :re_financing_income => 0.0,
          :re_financing_income_plus_taxes => 0.0,
          :re_operating_revenue => 13499.0,
          :re_operating_expense => 1646.0,
          :re_operating_income_from_sales_before_tax => 3979.0,
          :re_other_operating_income_before_tax => 50.0,
          :re_operating_income_from_sales_after_tax => 3041.5,
          :re_operating_income_after_tax => 3074.0,
          :re_net_financing_income_after_tax => 0.0,
          :re_net_income => 3074.0 },

        { :filename => "specs/testvectors/deere/2004_01_31.html",
          :date0 => "2004",
          :date1 => "2003",
          :operating_revenue => 3483.8,
          :cost_of_revenue => 2294.5,
          :operating_expense => 927.1,
          :operating_income_from_sales_before_tax => 262.2,
          :other_operating_income_before_tax => 0.0,
          :operating_income_before_tax => 262.2,
          :provision_for_tax => 92.6,
          :other_income_after_tax => 1.2,
          :net_income => 170.8,
          :re_financing_income => 147.3,
          :re_operating_revenue => 3189.1,
          :re_operating_expense => 779.7,
          :re_operating_income_from_sales_before_tax => 114.9,
          :re_other_operating_income_before_tax => 0.0,
          :re_operating_income_from_sales_after_tax => 73.855,
          :re_operating_income_after_tax => 75.055,
          :re_net_financing_income_after_tax => 95.745,
          :re_net_income => 170.8 },

        { :filename => "specs/testvectors/google/2009_09_30.html",
          :date0 => "2008",
          :date1 => "2009",
          :operating_revenue => 5541391.0,
          :cost_of_revenue => 2173390.0,
          :operating_expense => 1720436.0,
          :operating_income_from_sales_before_tax => 1647565.0,
          :other_operating_income_before_tax => 21217.0,
          :operating_income_before_tax => 1668782.0,
          :provision_for_tax => 378844.0,
          :other_income_after_tax => 0.0,
          :net_income => 1289938.0,
          :re_financing_income => 21217.0,
          :re_operating_revenue => 5541391.0,
          :re_operating_expense => 1720436.0,
          :re_operating_income_from_sales_before_tax => 1647565.0,
          :re_other_operating_income_before_tax => 0.0,
          :re_operating_income_from_sales_after_tax => 1276146.95,
          :re_operating_income_after_tax => 1276146.95,
          :re_net_financing_income_after_tax => 13791.05,
          :re_net_income => 1289938.0 },

        { :filename => "specs/testvectors/intel/2005_07_02.html",
          :date0 => "2005",
          :date1 => "2004",
          :date2 => "2005",
          :date3 => "2004",
          :operating_revenue => 9231.0,
          :cost_of_revenue => 4028.0,
          :operating_expense => 2554.0,
          :operating_income_from_sales_before_tax => 2649.0,
          :other_operating_income_before_tax => 105.0,
          :operating_income_before_tax => 2754.0,
          :provision_for_tax => 716.0,
          :other_income_after_tax => 0.0,
          :net_income => 2038.0,
          :re_financing_income => 105.0,
          :re_operating_revenue => 9231.0,
          :re_operating_expense => 2554.0,
          :re_operating_income_from_sales_before_tax => 2649.0,
          :re_other_operating_income_before_tax => 0.0,
          :re_operating_income_from_sales_after_tax => 1969.75,
          :re_operating_income_after_tax => 1969.75, 
          :re_net_financing_income_after_tax => 68.25,
          :re_net_income => 2038.0 },

        { :filename => "specs/testvectors/microsoft/2011_03_31.html",
          :date0 => "2011",
          :date1 => "2010",
          :date2 => "2011",
          :date3 => "2010",
          :operating_revenue => 16428.0,
          :cost_of_revenue => 3897.0,
          :operating_expense => 6822.0,
          :operating_income_from_sales_before_tax => 5709.0,
          :other_operating_income_before_tax => 316.0,
          :operating_income_before_tax => 6025.0,
          :provision_for_tax => 793.0,
          :other_income_after_tax => 0.0,
          :net_income => 5232.0,
          :re_financing_income => 0.0,
          :re_operating_revenue => 16428.0,
          :re_operating_expense => 6822.0,
          :re_operating_income_from_sales_before_tax => 5709.0,
          :re_other_operating_income_before_tax => 316.0,
          :re_operating_income_from_sales_after_tax => 5026.6,
          :re_operating_income_after_tax => 5232.0,
          :re_net_financing_income_after_tax => 0.0,
          :re_net_income => 5232.0 } ]

    @reporting_period = 0

    @vectors.each do |cur_vector|
      ten_q = SecEdgar::QuarterlyReport.new
      ten_q.log = Logger.new('sec_edgar.log')
      ten_q.log.level = Logger::DEBUG
      ten_q.parse(cur_vector[:filename])
      cur_vector[:ten_q] = ten_q
    end
  end

  let(:create_fin_stmt) do

    @bogus_filename = "/tmp/ao0gqq34q34g"

    # load a primary one
    @good_filename = "specs/testvectors/google/2010_03_31.html"

    @tenq = SecEdgar::QuarterlyReport.new
    @tenq.log = Logger.new('sec_edgar.log')
    @tenq.log.level = Logger::DEBUG
    @tenq.parse(@good_filename)
    @fin_stmt = @tenq.inc_stmt

    # load a second one (to test merging, etc)
    @good_filename2 = "specs/testvectors/google/2011_03_31.html"

    @tenq2 = SecEdgar::QuarterlyReport.new
    @tenq2.log = Logger.new('sec_edgar.log')
    @tenq2.log.level = Logger::DEBUG
    @tenq2.parse(@good_filename2)
    @fin_stmt2 = @tenq2.inc_stmt

  end

  ## it_should_behave_like 'SecEdgar::FinancialStatement' ## RE-ENABLE THIS LATER

  describe "#report_dates" do
    it "returns the report date for a given column" do
      @vectors[0][:ten_q].inc_stmt.report_dates[0].should == @vectors[0][:date0]
      @vectors[0][:ten_q].inc_stmt.report_dates[1].should == @vectors[0][:date1]
      @vectors[0][:ten_q].inc_stmt.report_dates[2].should == @vectors[0][:date2]
      @vectors[0][:ten_q].inc_stmt.report_dates[3].should == @vectors[0][:date3]
    end
    it "returns the report date for a given column" do
      @vectors[1][:ten_q].inc_stmt.report_dates[0].should == @vectors[1][:date0]
      @vectors[1][:ten_q].inc_stmt.report_dates[1].should == @vectors[1][:date1]
    end
    it "returns the report date for a given column" do
      @vectors[2][:ten_q].inc_stmt.report_dates[0].should == @vectors[2][:date0]
      @vectors[2][:ten_q].inc_stmt.report_dates[1].should == @vectors[2][:date1]
    end
    it "returns the report date for a given column" do
      @vectors[3][:ten_q].inc_stmt.report_dates[0].should == @vectors[3][:date0]
      @vectors[3][:ten_q].inc_stmt.report_dates[1].should == @vectors[3][:date1]
      @vectors[3][:ten_q].inc_stmt.report_dates[2].should == @vectors[3][:date2]
      @vectors[3][:ten_q].inc_stmt.report_dates[3].should == @vectors[3][:date3]
    end
    it "returns the report date for a given column" do
      @vectors[4][:ten_q].inc_stmt.report_dates[0].should == @vectors[4][:date0]
      @vectors[4][:ten_q].inc_stmt.report_dates[1].should == @vectors[4][:date1]
      @vectors[4][:ten_q].inc_stmt.report_dates[2].should == @vectors[4][:date2]
      @vectors[4][:ten_q].inc_stmt.report_dates[3].should == @vectors[4][:date3]
    end
  end

  describe "#operating_revenue" do
    it "returns the total revenues" do
      @vectors[0][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:operating_revenue])
    end
    it "returns the total revenues" do
      @vectors[1][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:operating_revenue])
    end
    it "returns the total revenues" do
      @vectors[2][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:operating_revenue])
    end
    it "returns the total revenues" do
      @vectors[3][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:operating_revenue])
    end
    it "returns the total revenues" do
      @vectors[4][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:operating_revenue])
    end
  end

  describe "#cost_of_revenue" do
    it "returns the total expenses" do
      @vectors[0][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:cost_of_revenue])
    end
    it "returns the total expenses" do
      @vectors[1][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:cost_of_revenue])
    end
    it "returns the total expenses" do
      @vectors[2][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:cost_of_revenue])
    end
    it "returns the total expenses" do
      @vectors[3][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:cost_of_revenue])
    end
    it "returns the total expenses" do
      @vectors[4][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:cost_of_revenue])
    end
  end

  describe "#gross_margin" do
    it "returns the total expenses" do
      gm = @vectors[0][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period] - @vectors[0][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period]
      @vectors[0][:ten_q].inc_stmt.gross_margin.cols[@reporting_period].should be_within(0.1).of(gm)
    end
    it "returns the total expenses" do
      gm = @vectors[1][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period] - @vectors[1][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period]
      @vectors[1][:ten_q].inc_stmt.gross_margin.cols[@reporting_period].should be_within(0.1).of(gm)
    end
    it "returns the total expenses" do
      gm = @vectors[2][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period] - @vectors[2][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period]
      @vectors[2][:ten_q].inc_stmt.gross_margin.cols[@reporting_period].should be_within(0.1).of(gm)
    end
    it "returns the total expenses" do
      gm = @vectors[3][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period] - @vectors[3][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period]
      @vectors[3][:ten_q].inc_stmt.gross_margin.cols[@reporting_period].should be_within(0.1).of(gm)
    end
    it "returns the total expenses" do
      gm = @vectors[4][:ten_q].inc_stmt.operating_revenue.cols[@reporting_period] - @vectors[4][:ten_q].inc_stmt.cost_of_revenue.cols[@reporting_period]
      @vectors[4][:ten_q].inc_stmt.gross_margin.cols[@reporting_period].should be_within(0.1).of(gm)
    end
  end

  describe "#operating_expense" do
    it "returns the total expenses" do
      @vectors[0][:ten_q].inc_stmt.operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:operating_expense])
    end
    it "returns the total expenses" do
      @vectors[1][:ten_q].inc_stmt.operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:operating_expense])
    end
    it "returns the total expenses" do
      @vectors[2][:ten_q].inc_stmt.operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:operating_expense])
    end
    it "returns the total expenses" do
      @vectors[3][:ten_q].inc_stmt.operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:operating_expense])
    end
    it "returns the total expenses" do
      @vectors[4][:ten_q].inc_stmt.operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:operating_expense])
    end
  end

  describe "#operating_income_from_sales_before_tax" do
    it "returns the total income from sales (before tax)" do
      @vectors[0][:ten_q].inc_stmt.operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:operating_income_from_sales_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[1][:ten_q].inc_stmt.operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:operating_income_from_sales_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[2][:ten_q].inc_stmt.operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:operating_income_from_sales_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[3][:ten_q].inc_stmt.operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:operating_income_from_sales_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[4][:ten_q].inc_stmt.operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:operating_income_from_sales_before_tax])
    end
  end

  describe "#other_operating_income_before_tax" do
    it "returns the total income from sales (before tax)" do
      @vectors[0][:ten_q].inc_stmt.other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:other_operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[1][:ten_q].inc_stmt.other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:other_operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[2][:ten_q].inc_stmt.other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:other_operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[3][:ten_q].inc_stmt.other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:other_operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[4][:ten_q].inc_stmt.other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:other_operating_income_before_tax])
    end
  end

  describe "#operating_income_before_tax" do
    it "returns the total income from sales (before tax)" do
      @vectors[0][:ten_q].inc_stmt.operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[1][:ten_q].inc_stmt.operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[2][:ten_q].inc_stmt.operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[3][:ten_q].inc_stmt.operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:operating_income_before_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[4][:ten_q].inc_stmt.operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:operating_income_before_tax])
    end
  end

  describe "#provision_for_tax" do
    it "returns the total income from sales (before tax)" do
      @vectors[0][:ten_q].inc_stmt.provision_for_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:provision_for_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[1][:ten_q].inc_stmt.provision_for_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:provision_for_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[2][:ten_q].inc_stmt.provision_for_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:provision_for_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[3][:ten_q].inc_stmt.provision_for_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:provision_for_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[4][:ten_q].inc_stmt.provision_for_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:provision_for_tax])
    end
  end

  describe "#other_income_after_tax" do
    it "returns the total income from sales (before tax)" do
      @vectors[0][:ten_q].inc_stmt.other_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:other_income_after_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[1][:ten_q].inc_stmt.other_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:other_income_after_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[2][:ten_q].inc_stmt.other_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:other_income_after_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[3][:ten_q].inc_stmt.other_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:other_income_after_tax])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[4][:ten_q].inc_stmt.other_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:other_income_after_tax])
    end
  end

  describe "#net_income" do
    it "returns the total income from sales (before tax)" do
      @vectors[0][:ten_q].inc_stmt.net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:net_income])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[1][:ten_q].inc_stmt.net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:net_income])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[2][:ten_q].inc_stmt.net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:net_income])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[3][:ten_q].inc_stmt.net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:net_income])
    end
    it "returns the total income from sales (before tax)" do
      @vectors[4][:ten_q].inc_stmt.net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:net_income])
    end
  end

  describe "#re_financing_income" do
    it "returns the reformulated, before-tax financing income" do
      @vectors[0][:ten_q].inc_stmt.re_financing_income.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_financing_income])
    end
    it "returns the reformulated, before-tax financing income" do
      @vectors[1][:ten_q].inc_stmt.re_financing_income.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_financing_income])
    end
    it "returns the reformulated, before-tax financing income" do
      @vectors[2][:ten_q].inc_stmt.re_financing_income.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_financing_income])
    end
    it "returns the reformulated, before-tax financing income" do
      @vectors[3][:ten_q].inc_stmt.re_financing_income.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_financing_income])
    end
    it "returns the reformulated, before-tax financing income" do
      @vectors[4][:ten_q].inc_stmt.re_financing_income.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_financing_income])
    end
  end

  describe "#re_operating_revenue" do
    it "returns the reformulated total revenues" do
      @vectors[0][:ten_q].inc_stmt.re_operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_operating_revenue])
    end
    it "returns the reformulated total revenues" do
      @vectors[1][:ten_q].inc_stmt.re_operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_operating_revenue])
    end
    it "returns the reformulated total revenues" do
      @vectors[2][:ten_q].inc_stmt.re_operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_operating_revenue])
    end
    it "returns the reformulated total revenues" do
      @vectors[3][:ten_q].inc_stmt.re_operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_operating_revenue])
    end
    it "returns the reformulated total revenues" do
      @vectors[4][:ten_q].inc_stmt.re_operating_revenue.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_operating_revenue])
    end
  end

  describe "#re_operating_expense" do
    it "returns the reformulated operating expenses" do
      @vectors[0][:ten_q].inc_stmt.re_operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_operating_expense])
    end
    it "returns the reformulated operating expenses" do
      @vectors[1][:ten_q].inc_stmt.re_operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_operating_expense])
    end
    it "returns the reformulated operating expenses" do
      @vectors[2][:ten_q].inc_stmt.re_operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_operating_expense])
    end
    it "returns the reformulated operating expenses" do
      @vectors[3][:ten_q].inc_stmt.re_operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_operating_expense])
    end
    it "returns the reformulated operating expenses" do
      @vectors[4][:ten_q].inc_stmt.re_operating_expense.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_operating_expense])
    end
  end

  describe "#re_operating_income_from_sales_before_tax" do
    it "returns the reformulated operating income from sales before tax" do
      @vectors[0][:ten_q].inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_operating_income_from_sales_before_tax])
    end
    it "returns the reformulated operating income from sales before tax" do
      @vectors[1][:ten_q].inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_operating_income_from_sales_before_tax])
    end
    it "returns the reformulated operating income from sales before tax" do
      @vectors[2][:ten_q].inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_operating_income_from_sales_before_tax])
    end
    it "returns the reformulated operating income from sales before tax" do
      @vectors[3][:ten_q].inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_operating_income_from_sales_before_tax])
    end
    it "returns the reformulated operating income from sales before tax" do
      @vectors[4][:ten_q].inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_operating_income_from_sales_before_tax])
    end
  end

  describe "#re_other_operating_income_before_tax" do
    it "returns the reformulated other operating income before tax tax" do
      @vectors[0][:ten_q].inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_other_operating_income_before_tax])
    end
    it "returns the reformulated other operating income before tax tax" do
      @vectors[1][:ten_q].inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_other_operating_income_before_tax])
    end
    it "returns the reformulated other operating income before tax tax" do
      @vectors[2][:ten_q].inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_other_operating_income_before_tax])
    end
    it "returns the reformulated other operating income before tax tax" do
      @vectors[3][:ten_q].inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_other_operating_income_before_tax])
    end
    it "returns the reformulated other operating income before tax tax" do
      @vectors[4][:ten_q].inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_other_operating_income_before_tax])
    end
  end

  # figure out taxes on financial items & other operating income; 
  # subtract this from taxes, as reported.
  # subtract result from "operating income from sales, before tax"
  # result is "operating income from sales, after tax"
  describe "#re_operating_income_from_sales_after_tax" do
    it "returns the reformulated operating income from sales after tax" do
      @vectors[0][:ten_q].inc_stmt.re_operating_income_from_sales_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_operating_income_from_sales_after_tax])
    end
    it "returns the reformulated operating income from sales after tax" do
      @vectors[1][:ten_q].inc_stmt.re_operating_income_from_sales_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_operating_income_from_sales_after_tax])
    end
    it "returns the reformulated operating income from sales after tax" do
      inc_stmt = @vectors[2][:ten_q].inc_stmt

      other_income =  inc_stmt.re_financing_income.cols[@reporting_period]
      other_income += inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period]

      tax_on_other_income = 0.35 * other_income
      tax_on_sales_income = inc_stmt.provision_for_tax.cols[@reporting_period] - tax_on_other_income

      re_operating_income_from_sales_after_tax = inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period] - tax_on_sales_income
      re_operating_income_from_sales_after_tax.should be_within(0.1).of(@vectors[2][:re_operating_income_from_sales_after_tax])

      @vectors[2][:ten_q].inc_stmt.re_operating_income_from_sales_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_operating_income_from_sales_after_tax])
    end
    it "returns the reformulated operating income from sales after tax" do
      @vectors[3][:ten_q].inc_stmt.re_operating_income_from_sales_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_operating_income_from_sales_after_tax])
    end
    it "returns the reformulated operating income from sales after tax" do
      @vectors[4][:ten_q].inc_stmt.re_operating_income_from_sales_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_operating_income_from_sales_after_tax])
    end
  end

  describe "#re_operating_income_after_tax" do

    it "returns the reformulated operating income after tax" do
      @vectors[0][:ten_q].inc_stmt.re_operating_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_operating_income_after_tax])
    end
    it "returns the reformulated operating income after tax" do
      @vectors[1][:ten_q].inc_stmt.re_operating_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_operating_income_after_tax])
    end
    it "returns the reformulated operating income after tax" do
      inc_stmt = @vectors[2][:ten_q].inc_stmt

      other_income = inc_stmt.re_financing_income.cols[@reporting_period]
      #other_income += inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period]

      tax_on_other_income = 0.35 * other_income
      tax_on_operating_income = inc_stmt.provision_for_tax.cols[@reporting_period] - tax_on_other_income

      re_operating_income_after_tax = inc_stmt.re_operating_income_from_sales_before_tax.cols[@reporting_period] + inc_stmt.re_other_operating_income_before_tax.cols[@reporting_period] - tax_on_operating_income
      re_operating_income_after_tax.should be_within(0.1).of(@vectors[2][:re_operating_income_after_tax])

      @vectors[2][:ten_q].inc_stmt.re_operating_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_operating_income_after_tax])
    end
    it "returns the reformulated operating income after tax" do
      @vectors[3][:ten_q].inc_stmt.re_operating_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_operating_income_after_tax])
    end
    it "returns the reformulated operating income after tax" do
      @vectors[4][:ten_q].inc_stmt.re_operating_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_operating_income_after_tax])
    end
  end


  # mutliply 35% (Tax rate) times "other (not-from-sales) operating income, before tax (a positive #) -- tax effect
  # subtract this from the "other operating income, before tax" 
  # add this to "other operating income, after tax"
  # add this to "operating income from sales, after tax"
  # result is  "operating income (after tax)"
  describe "#re_net_financing_income_after_tax" do

    it "returns the reformulated net financing income after tax" do
      @vectors[0][:ten_q].inc_stmt.re_net_financing_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_net_financing_income_after_tax])
    end
    it "returns the reformulated net financing income after tax" do
      @vectors[1][:ten_q].inc_stmt.re_net_financing_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_net_financing_income_after_tax])
    end
    it "returns the reformulated net financing income after tax" do
      @vectors[2][:ten_q].inc_stmt.re_net_financing_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_net_financing_income_after_tax])
    end
    it "returns the reformulated net financing income after tax" do
      @vectors[3][:ten_q].inc_stmt.re_net_financing_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_net_financing_income_after_tax])
    end
    it "returns the reformulated net financing income after tax" do
      @vectors[4][:ten_q].inc_stmt.re_net_financing_income_after_tax.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_net_financing_income_after_tax])
    end
  end


  # collect all before-tax financing income
  # multiply by 35% (tax rate)
  # add any after-tax financing income
  # result is net financing income after tax
  describe "#re_net_income" do

    it "returns the reformulated net income" do
      @vectors[0][:ten_q].inc_stmt.re_net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[0][:re_net_income])
    end
    it "returns the reformulated net income" do
      @vectors[1][:ten_q].inc_stmt.re_net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[1][:re_net_income])
    end
    it "returns the reformulated net income" do
      @vectors[2][:ten_q].inc_stmt.re_net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[2][:re_net_income])
    end
    it "returns the reformulated net income" do
      @vectors[3][:ten_q].inc_stmt.re_net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[3][:re_net_income])
    end
    it "returns the reformulated net income" do
      @vectors[4][:ten_q].inc_stmt.re_net_income.cols[@reporting_period].should be_within(0.1).of(@vectors[4][:re_net_income])
    end
  end


end
 
