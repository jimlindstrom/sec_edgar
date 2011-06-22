# sec_edgar_edgar_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

describe SecEdgar::Edgar do

  before(:each) do
    @good_ticker = 'GOOG'
    @bad_ticker = 'BADTICKER'

    @download_path = "/tmp/"

    @bogus_report_type = "10-kaq2"
    @report_type = "10-k"

    @edgar = SecEdgar::Edgar.new
    @edgar.log = Logger.new('sec_edgar.log')
    @edgar.log.level = Logger::DEBUG
  end
   
  describe "#good_ticker?" do
    it "returns false if given a bad ticker" do
      @edgar.good_ticker?(@bad_ticker).should == false
    end
    it "returns true if given a good ticker" do
      @edgar.good_ticker?(@good_ticker).should == true
    end
  end

  describe "#get_reports_urls" do
    it "returns nil if given a bad ticker" do
      @edgar.get_reports_urls(@bad_ticker, @report_type).nil?.should == true
    end
    it "returns nil if given a bogus report type (not 10-q or 10-k)" do
      @edgar.get_reports_urls(@good_ticker, @bogus_report_type).nil?.should == true
    end
    it "returns a non-empty list of URLs to be downloaded" do
      list_of_URLs = @edgar.get_reports_urls(@good_ticker, @report_type)
      list_of_URLs.length.should > 0
    end
  end

  describe "#download_10q_reports" do
    it "returns nil if given a bad ticker" do
      @edgar.download_10q_reports(@bad_ticker, @download_path).should == nil
    end
    it "returns a list of reports it downloaded (at least one per URL)" do
      list_of_URLs = @edgar.get_reports_urls(@good_ticker, @report_type)
      list_of_files = @edgar.download_10q_reports(@good_ticker, @download_path)
      list_of_files.length.should >= list_of_URLs.length
	  list_of_files[0].class.should == String
	  end
  end

  describe "#download_10k_reports" do
    it "returns nil if given a bad ticker" do
      @edgar.download_10k_reports(@bad_ticker, @download_path).should == nil
    end
    it "returns a list of files it downloaded (at least one per URL)" do
      list_of_URLs = @edgar.get_reports_urls(@good_ticker, @report_type)
      list_of_files = @edgar.download_10k_reports(@good_ticker, @download_path)
      list_of_files.length.should >= list_of_URLs.length
      list_of_files[0].class.should == String
    end
  end

  describe "#get_10q_reports" do
    it "returns nil if given a bad ticker" do
      @edgar.get_10q_reports(@bad_ticker, @download_path).should == nil
    end
    it "returns a list of 10_q's it downloaded (at least one per URL)" do
      list_of_URLs = @edgar.get_reports_urls(@good_ticker, @report_type)
      list_of_reports = @edgar.get_10q_reports(@good_ticker, @download_path)
      list_of_reports.length.should >= list_of_URLs.length
      list_of_reports[0].class.should == SecEdgar::QuarterlyReport
    end
  end

  describe "#get_10k_reports" do
    it "returns nil if given a bad ticker" do
      @edgar.get_10k_reports(@bad_ticker, @download_path).should == nil
    end
    it "returns a list of 10_k's it downloaded (at least one per URL)" do
      list_of_URLs = @edgar.get_reports_urls(@good_ticker, @report_type)
      list_of_reports = @edgar.get_10k_reports(@good_ticker, @download_path)
      list_of_reports.length.should >= list_of_URLs.length
      list_of_reports[0].class.should == SecEdgar::AnnualReport
    end
  end
    
end

