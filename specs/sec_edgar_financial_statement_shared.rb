# sec_edgar_financial_statement_spec.rb

shared_examples_for 'SecEdgar::FinancialStatement' do

  before(:each) do
    create_fin_stmt
  end
    
  describe "#write_to_csv" do
    it "writes itself to a given CSV file" do
      #FIXME
    end
  end

  describe "#merge" do
    it "merges a second financial statement into itself" do
      #FIXME
    end
  end

end

