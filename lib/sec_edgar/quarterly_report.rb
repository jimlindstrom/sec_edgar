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
      [/consolidated[ \n\r]*balance[ \n\r]*sheet[s]*/,
       /condensed[ \n\r]*balance[ \n\r]*sheet[s]*/,
       /balance[ \n\r]*sheet[s]*/ ]

    INC_STMT_REGEXES = 
      [/consolidated[ \n\ra-z]*statement[s]*[ \n\r]of[ \n\r]income/,
       /statement[s]*[ \n\r]of[ \n\r]consolidated[ \r\n]income/,
       /consolidated[ \n\ra-z]*statement[s]*[ \n\r]of[ \n\r]operations/,
       /income[ \n\r]*statement[s]*/ ]

    CASH_FLOW_STMT_REGEXES = 
      [/consolidated[ \n\rA-Za-z]*statement[s]*[ \n\r]of[ \n\r]cash[ \n\r]flows/,
       /statement[s]*[ \n\r]of[ \n\r]consolidated[ \n\r]cash[ \n\r]flows/,
       /cash[ \n\r]flows[ \n\r]statement[s]*/ ]

    attr_accessor :log, :bal_sheet, :inc_stmt, :cash_flow_stmt
  
    def initialize
      @bal_sheet = nil
      @inc_stmt = nil
      @cash_flow_stmt = nil
    end

    def write_summary(filename)
      def calc_growth_rates(a)
        a[0..(a.length-2)].zip(a[1..a.length]).collect { |x,y| (Float(y)-x)/x }
      end

      def calc_ratios(a, b)
        a.zip(b).collect{ |x,y| Float(x)/y }
      end

      def calc_reois(ois, noas)
        ois[1..(ois.length-1)].zip(noas[0..(noas.length-2)]).collect { |oi,noa| Float(oi)-(0.1*noa) }
      end

      CSV.open(filename, "wb") do |csv|
        csv << [""] + @bal_sheet.report_dates
        csv << [""]

        csv << ["Balance Sheet"]
        csv << ["  NOA"]
        csv << ["    OA" ] + @bal_sheet.total_oa.cols
        csv << ["    OL" ] + @bal_sheet.total_ol.cols
        csv << ["    NOA"] + @bal_sheet.noa.cols
        csv << ["  NFA"]
        csv << ["    FA" ] + @bal_sheet.total_fa.cols
        csv << ["    FL" ] + @bal_sheet.total_fl.cols
        csv << ["    NFA"] + @bal_sheet.nfa.cols
        csv << ["  CSE"]
        csv << ["    CSE"] + @bal_sheet.cse.cols
        csv << [""]

        csv << ["Balance Sheet Analysis"]
        csv << ["  Composition ratio"    ] + @bal_sheet.noa.cols.zip(@bal_sheet.cse.cols).collect { |x,y| x/y }
        csv << ["  NOA growth",        ""] + calc_growth_rates(@bal_sheet.noa.cols)
        csv << ["  CSE growth",        ""] + calc_growth_rates(@bal_sheet.cse.cols)
        csv << [""]

        csv << ["Income Statement"]
        csv << ["  Operating revenues"       ] + @inc_stmt.re_operating_revenue.cols
        csv << ["  Gross margin"             ] + @inc_stmt.re_gross_margin.cols
        csv << ["  OI from sales (after tax)"] + @inc_stmt.re_operating_income_from_sales_after_tax.cols
        csv << ["  OI (after tax)"           ] + @inc_stmt.re_operating_income_after_tax.cols
        csv << ["  Financing income"         ] + @inc_stmt.re_net_financing_income_after_tax.cols
        csv << ["  Net income"               ] + @inc_stmt.re_net_income.cols
        csv << [""]

        csv << ["Income Statement Margin Analysis"]
        csv << ["  Gross margin"] + calc_ratios(@inc_stmt.re_gross_margin.cols,                          @inc_stmt.re_operating_revenue.cols)
        csv << ["  Sales PM"    ] + calc_ratios(@inc_stmt.re_operating_income_from_sales_after_tax.cols, @inc_stmt.re_operating_revenue.cols)
        csv << ["  PM"          ] + calc_ratios(@inc_stmt.re_operating_income_after_tax.cols,            @inc_stmt.re_operating_revenue.cols)
        csv << ["  FI / Sales"  ] + calc_ratios(@inc_stmt.re_net_financing_income_after_tax.cols,        @inc_stmt.re_operating_revenue.cols)
        csv << ["  NI / Sales"  ] + calc_ratios(@inc_stmt.re_net_income.cols,                            @inc_stmt.re_operating_revenue.cols)
        csv << [""]

        csv << ["Income Statement Ratio Analysis"]
        csv << ["  Sales / NOA (ATO)"   ] + calc_ratios(@inc_stmt.re_operating_revenue.cols, @bal_sheet.noa.cols)
        csv << ["  Revenue Growth",   ""] + calc_growth_rates(@inc_stmt.re_operating_revenue.cols)
        csv << ["  Core OI Growth",   ""] + calc_growth_rates(@inc_stmt.re_operating_income_from_sales_after_tax.cols)
        csv << ["  OI Growth",        ""] + calc_growth_rates(@inc_stmt.re_operating_income_after_tax.cols)
        csv << ["  FI / NFA",           ] + calc_ratios(@inc_stmt.re_net_financing_income_after_tax.cols, @bal_sheet.nfa.cols)
        csv << ["  ReOI (at 10%)",    ""] + calc_reois(@inc_stmt.re_operating_income_after_tax.cols, @bal_sheet.noa.cols)
        csv << [""]

      end
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
                @log.info("failed to parse balance sheet, resetting to try again.") if @log
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
