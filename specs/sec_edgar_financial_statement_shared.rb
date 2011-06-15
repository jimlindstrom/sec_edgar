# sec_edgar_financial_statement_spec.rb

shared_examples_for 'SecEdgar::FinancialStatement' do

  before(:each) do
    create_fin_stmt
  end
   
  describe "#parse" do
    it "returns false if the file doesn't exist or doesn't contain an SEC financial statement" do
      @fin_stmt.parse(@bogus_filename).should == false
    end
    it "returns true if the file exists and contains an SEC financial statement" do
      @fin_stmt.parse(@filename).should == true
    end
    it "creates rows attribute containing the financial statement" do
      @fin_stmt.parse(@filename)
      @fin_stmt.rows.class.should == Array #????
    end
  end

end

