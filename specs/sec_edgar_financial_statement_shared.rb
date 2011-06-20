# sec_edgar_financial_statement_spec.rb

shared_examples_for 'SecEdgar::FinancialStatement' do

  before(:each) do
    create_fin_stmt
  end
    
  describe "#parse" do
    it "is a 3-column statement (header, reporting period 1, reporting period 2)" do
      puts @fin_stmt.rows.first
      @fin_stmt.rows.first.length.should == 3
    end
    it "is a 3-column statement (header, reporting period 1, reporting period 2)" do
      @fin_stmt2.rows.first.length.should == 3
    end
  end

  describe "#merge" do
    it "results in @rows that does not have any row labels not found in the original statements" do
      @original_width = @fin_stmt.rows.first.length

      @all_row_labels = @fin_stmt.rows.collect { |r| r[0].text } + @fin_stmt2.rows.collect { |r| r[0].text }
      @expected_rows  = @all_row_labels.uniq.sort

      @fin_stmt.merge(@fin_stmt2)

      @actual_rows = @fin_stmt.rows.collect { |r| r[0].text }.sort + @fin_stmt.rows.collect { |r| r[@original_width].text }
      @actual_rows = @actual_rows.uniq.sort

      @extra_rows   = @actual_rows - @expected_rows
      @missing_rows = @expected_rows - @actual_rows

      @extra_rows.should == []
    end

    it "results in @rows that contains a row for each row in either of the original statements" do
      @original_width = @fin_stmt.rows.first.length

      @all_row_labels = @fin_stmt.rows.collect { |r| r[0].text } + @fin_stmt2.rows.collect { |r| r[0].text }
      @expected_rows  = @all_row_labels.uniq.sort

      @fin_stmt.merge(@fin_stmt2)

      @actual_rows = @fin_stmt.rows.collect { |r| r[0].text }.sort + @fin_stmt.rows.collect { |r| r[@original_width].text }
      @actual_rows = @actual_rows.uniq.sort

      @extra_rows   = @actual_rows - @expected_rows
      @missing_rows = @expected_rows - @actual_rows

      @missing_rows.should == []
    end

    it "results in @rows that is as wide as the sum of both statement's widths" do
      @expected_width = @fin_stmt.rows.first.length + @fin_stmt2.rows.first.length
      @fin_stmt.merge(@fin_stmt2)
      @fin_stmt.rows.first.length.should == @expected_width
    end
  end

end

