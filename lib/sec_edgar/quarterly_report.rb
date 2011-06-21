# FIXME put this function somewhere else
def traverse_for_table(next_elem, depth)
  #puts "next_elem(#{depth}): #{next_elem.name}"
  return next_elem if (next_elem.name == "table")
  return nil if (depth == 0)
  tmp = next_elem.nodes_at(1)
  return traverse_for_table(tmp.first,        depth-1) if (tmp.length > 0)
  return traverse_for_table(next_elem.parent, depth-1)
end

class String
  def match_regexes(regex_arr)
    regex_arr.each do |cur_regex|
      if self =~ cur_regex
        return true
      end
    end
    return false
  end
end

module SecEdgar

  class QuarterlyReport # this can also load an annual report
    SEARCH_DEPTH = 20

    attr_accessor :bal_sheet, :inc_stmt, :cash_flow_stmt
  
    def initialize
      @bal_sheet = nil
      @inc_stmt = nil
      @cash_flow_stmt = nil
    end
   
    BAL_SHEET_REGEXES = 
      [/consolidated[ \n\ra-z]*balance[ \n\r]sheets/,
       /balance[ \n\r]sheets/ ]

    INC_STMT_REGEXES = 
      [/consolidated[ \n\ra-z]*statements[ \n\r]of[ \n\r]income/,
       /consolidated[ \n\ra-z]*statements[ \n\r]of[ \n\r]operations/,
       /income[ \n\r]*statements/ ]

    CASH_FLOW_STMT_REGEXES = 
      [/consolidated[ \n\rA-Za-z]*statements[ \n\r]of[ \n\r]cash[ \n\r]flows/,
       /cash[ \n\r]flows[ \n\r]statements/ ]

    def parse(filename)
  
      begin
        fh = File.open(filename, "r")
        doc = Hpricot(fh)
        fh.close
      rescue
        return false
      end      

      doc.search("b").each do |cur_elem|
        if @bal_sheet.nil? and cur_elem.to_html.downcase.match_regexes(BAL_SHEET_REGEXES) then
          table_elem = traverse_for_table(cur_elem, SEARCH_DEPTH)
          if not table_elem.nil? 
            @bal_sheet = BalanceSheet.new
            ret = @bal_sheet.parse(table_elem)
            return false if ret == false
          end

        elsif @inc_stmt.nil? and cur_elem.to_html.downcase.match_regexes(INC_STMT_REGEXES) then
          table_elem = traverse_for_table(cur_elem, SEARCH_DEPTH)
          if not table_elem.nil? 
            @inc_stmt = IncomeStatement.new
            ret = @inc_stmt.parse(table_elem)
            return false if ret == false
          end

        elsif @cash_flow_stmt.nil? and cur_elem.to_html.downcase.match_regexes(CASH_FLOW_STMT_REGEXES) then
          table_elem = traverse_for_table(cur_elem, SEARCH_DEPTH)
          if not table_elem.nil? 
            @cash_flow_stmt = CashFlowStatement.new
            ret = @cash_flow_stmt.parse(table_elem)
            return false if ret == false
          end

        end
      end
  
      raise "Failed to parse balance sheet from #{filename}" if @bal_sheet.nil?
      raise "Failed to parse income statement from #{filename}" if @inc_stmt.nil?
      raise "Failed to parse cash flow statement from #{filename}" if @cash_flow_stmt.nil?
      return false if @bal_sheet == nil
      return false if @inc_stmt == nil
      return false if @cash_flow_stmt == nil
      return true
    end
  end
  
end
