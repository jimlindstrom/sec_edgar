# FIXME put this function somewhere else
def traverse_for_table(next_elem, depth)
  return next_elem if (next_elem.name == "table")
  return nil if (depth == 0)
  tmp = next_elem.next
  return traverse_for_table(tmp,              depth-1) if !tmp.nil?
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

    BAL_SHEET_REGEXES = 
      [/consolidated[ \n\r]balance[ \n\r]sheets/,
       /condensed[ \n\r]balance[ \n\r]sheets/,
       /balance[ \n\r]*sheets/ ]

    INC_STMT_REGEXES = 
      [/consolidated[ \n\ra-z]*statements[ \n\r]of[ \n\r]income/,
       /consolidated[ \n\ra-z]*statements[ \n\r]of[ \n\r]operations/,
       /income[ \n\r]*statements/ ]

    CASH_FLOW_STMT_REGEXES = 
      [/consolidated[ \n\rA-Za-z]*statements[ \n\r]of[ \n\r]cash[ \n\r]flows/,
       /cash[ \n\r]flows[ \n\r]statements/ ]

    attr_accessor :log, :bal_sheet, :inc_stmt, :cash_flow_stmt
  
    def initialize
      @bal_sheet = nil
      @inc_stmt = nil
      @cash_flow_stmt = nil
    end

    def parse(filename)
  
      @log.info("parsing 10q from #{filename}") if @log

      begin
        fh = File.open(filename, "r")
        doc = Hpricot(fh)
        fh.close
      rescue
        return false
      end      

      elems = doc.search("b") + doc.search("p") + doc.search("font")

      # assumes the regexes are in descending priority. searches document for 
      # each one until you find first one.
      cur_regexes = Array.new(BAL_SHEET_REGEXES)
      while not cur_regexes.empty?
        cur_regex = cur_regexes.shift
        @log.debug("trying to match balance sheet regex \"#{cur_regex}\"") if @log
        elems.each do |elem|
          # match to see if this element contains the regex in question
          if bal_sheet.nil? and elem.inner_text.downcase =~ cur_regex
            @log.debug("matched bal sheet regex at tag \"#{elem.inner_text}\"") if @log
            table_elem = traverse_for_table(elem, SEARCH_DEPTH)
            if not table_elem.nil? 
              @log.info("parsing balance sheet, at tag \"#{elem.inner_text}\"") if @log
              @bal_sheet = BalanceSheet.new
              @bal_sheet.log = @log if @log
              if @bal_sheet.parse(table_elem) == false
                @bal_sheet = nil # discard bogus parse attempts
              else
                @log.info("parsing of balance sheet succeeded") if @log
                cur_regexes = [] # done
              end
            end
          end
        end
      end
      raise "Failed to parse balance sheet from #{filename}" if @bal_sheet.nil?

      # assumes the regexes are in descending priority. searches document for 
      # each one until you find first one.
      cur_regexes = Array.new(INC_STMT_REGEXES)
      while not cur_regexes.empty?
        cur_regex = cur_regexes.shift
        @log.debug("trying to match income statement regex \"#{cur_regex}\"") if @log
        elems.each do |elem|
          # match to see if this element contains the regex in question
          if inc_stmt.nil? and elem.inner_text.downcase =~ cur_regex
            @log.debug("matched income stmt regex at tag \"#{elem.inner_text}\"") if @log
            table_elem = traverse_for_table(elem, SEARCH_DEPTH)
            if not table_elem.nil? 
              @log.info("parsing income stmt, at tag \"#{elem.inner_text}\"") if @log
              @inc_stmt = IncomeStatement.new
              @inc_stmt.log = @log if @log
              if @inc_stmt.parse(table_elem) == false
                @inc_stmt = nil # discard bogus parse attempts
              else
                @log.info("parsing of income stmt succeeded") if @log
                cur_regexes = [] # done
              end
            end
          end
        end
      end
      raise "Failed to parse income statement from #{filename}" if @inc_stmt.nil?

      # assumes the regexes are in descending priority. searches document for 
      # each one until you find first one.
      cur_regexes = Array.new(CASH_FLOW_STMT_REGEXES)
      while not cur_regexes.empty?
        cur_regex = cur_regexes.shift
        @log.debug("trying to match cash flow statement regex \"#{cur_regex}\"") if @log
        elems.each do |elem|
          # match to see if this element contains the regex in question
          if @cash_flow_stmt.nil? and elem.inner_text.downcase =~ cur_regex
            @log.debug("matched cash flow stmt regex at tag \"#{elem.inner_text}\"") if @log
            table_elem = traverse_for_table(elem, SEARCH_DEPTH)
            if not table_elem.nil? 
              @log.info("parsing cash flow stmt, at tag \"#{elem.inner_text}\"") if @log
              @cash_flow_stmt = CashFlowStatement.new
              @cash_flow_stmt.log = @log if @log
              if @cash_flow_stmt.parse(table_elem) == false
                @cash_flow_stmt = nil # discard bogus parse attempts
              else
                @log.info("parsing of cash flow stmt succeeded") if @log
                cur_regexes = [] # done
              end
            end
          end
        end
      end
      raise "Failed to parse cash flow statement from #{filename}" if @cash_flow_stmt.nil?

      return false if (@bal_sheet == nil) or (@inc_stmt == nil) or (@cash_flow_stmt == nil)
      return true
    end

  end
  
end
