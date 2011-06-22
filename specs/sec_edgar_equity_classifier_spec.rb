# sec_edgar_equity_classifier_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

describe SecEdgar::EquityClassifier do

  before(:each) do
    @ec = SecEdgar::EquityClassifier.new
  end
   
  describe "#classify" do
    it "returns a hash of 'class' and 'confidence'" do
      @ec.classify('this is a test').keys.should == [:class, :confidence]
    end

    it "classifies 'preferred stock, 0.001 par value per share, 100,000 shares authorized no shares issued and outstanding' as preferred equity" do
      @ec.classify('preferred stock, 0.001 par value per share, 100,000 shares authorized no shares issued and outstanding')[:class].should == :pse
    end

    it "classifies 'common stock and paidin capitalshares authorized 24,000 outstanding 8,431 and8,668' as common equity" do
      @ec.classify('common stock and paidin capitalshares authorized 24,000 outstanding 8,431 and8,668')[:class].should == :cse
    end
  end

end

