# sec_edgar_liab_classifier_spec.rb

$LOAD_PATH << './lib'
require 'sec_edgar'

describe SecEdgar::LiabClassifier do

  before(:each) do
    @ac = SecEdgar::LiabClassifier.new
  end
   
  describe "#classify" do
    it "returns a hash of 'class' and 'confidence'" do
      @ac.classify('this is a test').keys.should == [:class, :confidence]
    end

    it "classifies 'deferred revenue' as an operational liability" do
      @ac.classify('deferred revenue')[:class].should == :ol
    end

    it "classifies 'deferred income taxes' as a financial liability" do
      @ac.classify('deferred income taxes')[:class].should == :fl
    end
  end

end

