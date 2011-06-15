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
  
      begin
        fh = File.open(filename, "r")
        doc = Hpricot(fh)
        fh.close
      rescue
        return false
      end
      
      elems = doc.children[0].children[1].children[1].children[1].children[1].children[1].children[1].children[2].children
      
      (0..(elems.length-1)).each do |elem_idx|
      
        if elems[elem_idx].to_html =~ /CONSOLIDATED[ \n\r]BALANCE[ \n\r]SHEETS/ then
          (1..8).each do |elem_offset|
            search_idx = elem_idx + elem_offset
            if elems[search_idx].pathname == "table" then
              @bal_sheet = BalanceSheet.new
              ret = @bal_sheet.parse(elems[search_idx])
              return false if ret == false
            end
          end
        elsif elems[elem_idx].to_html =~ /CONSOLIDATED[ \n\r]STATEMENTS[ \n\r]OF[ \n\r]INCOME/ then
          (1..8).each do |elem_offset|
            search_idx = elem_idx + elem_offset
            if elems[search_idx].pathname == "table" then
              @inc_stmt = IncomeStatement.new
              ret = @inc_stmt.parse(elems[search_idx])
              return false if ret == false
            end
          end
        elsif elems[elem_idx].to_html =~ /CONSOLIDATED[ \n\r]STATEMENTS[ \n\r]OF[ \n\r]CASH[ \n\r]FLOWS/ then
          (1..8).each do |elem_offset|
            search_idx = elem_idx + elem_offset
            if elems[search_idx].pathname == "table" then
              @cash_flow_stmt = CashFlowStatement.new
              ret = @cash_flow_stmt.parse(elems[search_idx])
              return false if ret == false
            end
          end
        end
      end
  
      return false if @bal_sheet == nil
      return false if @inc_stmt == nil
      return false if @cash_flow_stmt == nil
      return true
    end
  end
  
end
