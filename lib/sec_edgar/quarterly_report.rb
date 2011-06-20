# FIXME put this function somewhere else
def traverse_for_table(next_elem, depth)
  return next_elem if next_elem.name == "table"
  return nil if depth == 0
  return traverse_for_table(next_elem.nodes_at(1).first, depth-1) if next_elem.nodes_at(1).length > 0
  return traverse_for_table(next_elem.parent,            depth-1)
end

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

      doc.search("b").keep_if{ |b| b.to_html =~ /CONSOLIDATED/ }.each do |cur_elem|
        if cur_elem.to_html =~ /CONSOLIDATED[ \n\r]BALANCE[ \n\r]SHEETS/ then
          table_elem = traverse_for_table(cur_elem, 11)
          raise "Parse Error" if table_elem.nil? 
          @bal_sheet = BalanceSheet.new
          ret = @bal_sheet.parse(table_elem)
          return false if ret == false

        elsif cur_elem.to_html =~ /CONSOLIDATED[ \n\r]STATEMENTS[ \n\r]OF[ \n\r]INCOME/ then
          table_elem = traverse_for_table(cur_elem, 11)
          raise "Parse Error" if table_elem.nil? 
          @inc_stmt = IncomeStatement.new
          ret = @inc_stmt.parse(table_elem)
          return false if ret == false

        # FIXME: this isn't working....
        elsif cur_elem.to_html =~ /CONSOLIDATED[ \n\r]STATEMENTS[ \n\r]OF[ \n\r]CASH[ \n\r]FLOWS/ then
          table_elem = traverse_for_table(cur_elem, 11)
          raise "Parse Error" if table_elem.nil? 
          @cash_flow_stmt = CashFlowStatement.new
          ret = @cash_flow_stmt.parse(table_elem)
          return false if ret == false

        end
      end
  
      return false if @bal_sheet == nil
      return false if @inc_stmt == nil
      return false if @cash_flow_stmt == nil
      return true
    end
  end
  
end
