module SecEdgar

  class QuarterlyReport # this can also load an annual report
    attr_accessor :bal_sheet, :inc_stmt, :cash_flow_stmt
  
    def initialize
      @bal_sheet = nil
      @inc_stmt = nil
      @cash_flow_stmt = nil
    end
  
    def normalize
      @bal_sheet.normalize unless @bal_sheet == nil
      @inc_stmt.normalize unless @inc_stmt == nil
      @cash_flow_stmt.normalize unless @cash_flow_stmt == nil
    end
  
    def parse(filename)
  
      fh = File.open(filename, "r")
      doc = Hpricot(fh)
      fh.close
      
      elems = doc.children[0].children[1].children[1].children[1].children[1].children[1].children[1].children[2].children
      
      (0..(elems.length-1)).each do |elem_idx|
      
        if elems[elem_idx].to_html =~ /CONSOLIDATED[ \n\r]BALANCE[ \n\r]SHEETS/ then
          (1..8).each do |elem_offset|
            search_idx = elem_idx + elem_offset
            if elems[search_idx].pathname == "table" then
              @bal_sheet = BalanceSheet.new
              @bal_sheet.parse_edgar_fin_stmt(elems[search_idx])
            end
          end
        elsif elems[elem_idx].to_html =~ /CONSOLIDATED[ \n\r]STATEMENTS[ \n\r]OF[ \n\r]INCOME/ then
          (1..8).each do |elem_offset|
            search_idx = elem_idx + elem_offset
            if elems[search_idx].pathname == "table" then
              @inc_stmt = IncomeStatement.new
              @inc_stmt.parse_edgar_fin_stmt(elems[search_idx])
            end
          end
        elsif elems[elem_idx].to_html =~ /CONSOLIDATED[ \n\r]STATEMENTS[ \n\r]OF[ \n\r]CASH[ \n\r]FLOWS/ then
          (1..8).each do |elem_offset|
            search_idx = elem_idx + elem_offset
            if elems[search_idx].pathname == "table" then
              @cash_flow_stmt = CashFlowStatement.new
              @cash_flow_stmt.parse_edgar_fin_stmt(elems[search_idx])
            end
          end
        end
      end
  
      puts "WARNING: failed to parse balance sheet" if @bal_sheet == nil
      puts "WARNING: failed to parse income statement" if @inc_stmt == nil
      puts "WARNING: failed to parse cash flow statement" if @cash_flow_stmt == nil
    end
  end
  
end
