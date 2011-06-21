# sec_edgar_asset_classifier_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

describe SecEdgar::AssetClassifier do

  before(:each) do
    @ac = SecEdgar::AssetClassifier.new
  end
   
  describe "#classify" do
    it "returns a hash of 'class' and 'confidence'" do
      @ac.classify('this is a test').keys.should == [:class, :confidence]
    end

    it "classifies 'prepaid revenue' as an operational asset" do
      @ac.classify('prepaid revenue')[:class].should == :oa
    end

    it "classifies 'cash and cash equivalents' as a financial asset" do
      @ac.classify('cash and cash equivalents')[:class].should == :fa
    end
  end

end

