module SecEdgar

  class IncomeStatement < FinancialStatement
    attr_accessor :operating_revenue, :cost_of_revenue, :gross_margin
    attr_accessor :operating_expense, :operating_income_from_sales_before_tax
    attr_accessor :other_operating_income_before_tax, :operating_income_before_tax
    attr_accessor :provision_for_tax, :operating_income_after_tax
    attr_accessor :other_income_after_tax, :net_income

    attr_accessor :re_financing_income, :re_operating_revenue, :re_gross_margin
    attr_accessor :re_operating_expense, :re_operating_income_from_sales_before_tax

    def initialize
      super()
      @name = "Income Statement"

      # as stated, line items
      @revenues = [] # array of rows
      @operating_expenses = [] # array of rows
      @other_operating_incomes_before_tax = [] # array of rows
      @other_incomes_after_tax = [] # array of rows

      # as stated, totals
      @operating_revenue = [] # array of floats
      @cost_of_revenue = [] # array of floats
      @gross_margin = [] # array of floats
      @operating_expense = [] # array of floats
      @operating_income_from_sales_before_tax = [] # array of floats
      @other_operating_income_before_tax = [] # array of floats
      @operating_income_before_tax = [] # array of floats
      @provision_for_tax = [] # array of floats
      @operating_income_after_tax = [] # array of floats
      @other_income_after_tax = [] # array of floats
      @net_income = [] # array of floats

      # reformulated, totals
      @re_financing_income = [] # array of floats
      @re_operating_revenue = [] # array of floats
      @re_gross_margin = [] # array of floats
      @re_operating_expense = [] # array of floats
      @re_operating_income_from_sales_before_tax = [] # array of floats
    end

    def parse(edgar_fin_stmt)
      # pull the table into rows (akin to CSV)
      return false if not super(edgar_fin_stmt)

      # text-matching to pull out dates, net amounts, etc.
      parse_reporting_periods
  
      # restate it
      return false if not parse_income_stmt_state_machine
      return false if not calculate_financing_income
      return false if not calculate_re_operating_income_from_sales_before_tax
    end

  private

    def parse_reporting_periods
      # pull out the date ranges
      @rows.each_with_index do |row, idx|
  
        # Match [X Months Ended  September 30,][Y Months Ended   June 30,]
        #       [2003][2004][2003][2004]
        if String(row[0].text).downcase.match(/months[^A-Za-z]*ended/) and
           String(row[1].text).downcase.match(/months[^A-Za-z]*ended/) then
          @rows[idx].insert(1,"")
          @rows[idx].insert(0,"")
          @rows[idx+1].insert(0,"")
  
        # Match [Month Ended]
        #       [Mar 1, 2003][Mar 1, 2004]
        elsif String(row[0].text).downcase.match(/month.*ended/) then
          if row.length < 2 then
            @rows[idx].concat(@rows[idx+1])
            @rows.delete_at(idx+1)
          end
  
        # Match [Year Ended]
        #       [Mar 1, 2003][Mar 1, 2004]
        elsif String(row[0].text).downcase.match(/year.*ended/) then
          if row.length < 2 then
            @rows[idx].concat(@rows[idx+1])
            @rows.delete_at(idx+1)
          end
        end
      end
    end

    def parse_income_stmt_state_machine
      
      state = :waiting_for_revenues
      @rows.each do |cur_row|
        @log.debug("income statement parser.  Cur label: #{cur_row[0].text}") if @log
        next_state = nil
        case state
        when :waiting_for_revenues
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /(net sales|net revenue|revenue)/
            if cur_row[1].val.nil? #  there's a list of individual revenue line items cominng
              next_state = :reading_revenues
            else # there's no lst of revenues coming, just the total on this line
              @operating_revenue = cur_row.collect { |x| x.val || nil }
              next_state = :reading_cost_of_revenue
            end
          else
            # ignore
          end

        when :reading_revenues
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /total/
            @operating_revenue = cur_row.collect { |x| x.val || nil }
            next_state = :reading_cost_of_revenue
          else
            @revenues.push cur_row
          end

        when :reading_cost_of_revenue
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /cost of (revenue|sales)/
            @cost_of_revenue = cur_row.collect { |x| x.val || nil }
            @gross_margin = array_diff_FF(@operating_revenue, @cost_of_revenue)
            next_state = :reading_operating_expenses
          end

        when :reading_operating_expenses
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /(^total|^operating expense[s]*$)/
            @operating_income_from_sales_before_tax = array_diff_FF(@gross_margin, @operating_expense)
            next_state = :reading_other_operating_expenses_before_tax
          elsif !cur_row[0].nil? and cur_row[0].text.downcase =~ /gross margin/
            # ignore
          else
            @operating_expenses.push cur_row
            @operating_expense = cur_row.zip(@operating_expense || [ ]).collect do |x,y|  ## FIXME: replace with helper
              if x.val.nil? and y.nil?
                nil
              elsif x.val.nil? and !y.nil?
                y
              elsif y.nil?
                x.val
              else
                x.val + y
              end
            end
            @log.debug("Income statement parser state machine, OE[1]: #{@operating_expense[1]}") if @log
          end

        when :reading_other_operating_expenses_before_tax
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /^provision for [income ]*tax/
            if @other_operating_income_before_tax[1].nil?
              @other_operating_income_before_tax = nil_and_n_zeros(@gross_margin.length - 1)
            end
            @operating_income_before_tax = array_sum_FF(@operating_income_from_sales_before_tax, @other_operating_income_before_tax)
            @provision_for_tax = cur_row.collect { |x| x.val || nil }
            @operating_income_after_tax = array_diff_FF(@operating_income_before_tax, @provision_for_tax)
            next_state = :reading_other_incomes_after_tax
          elsif !cur_row[0].nil? and cur_row[0].text.downcase =~ /(operating income|^income.*before.*tax|income from operations)/
            # ignore this total line
          else
            @other_operating_incomes_before_tax.push cur_row
            @other_operating_income_before_tax = cur_row.zip(@other_operating_income_before_tax || [ ]).collect do |x,y|  # replace with helper
              if x.val.nil? and y.nil?
                nil
              elsif x.val.nil? and !y.nil?
                y
              elsif y.nil?
                x.val
              else
                x.val + y
              end
            end

          end

        when :reading_other_incomes_after_tax
          if !cur_row[0].nil? and cur_row[0].text.downcase =~ /net income/
            if @other_income_after_tax[1].nil?
              @other_income_after_tax = nil_and_n_zeros(@gross_margin.length - 1)
            end
            @net_income = array_sum_FF(@operating_income_after_tax, @other_income_after_tax)
            next_state = :done
          elsif !cur_row[0].nil? and cur_row[0].text.downcase =~ /(^income of consolidated group$|^total$)/
            # ignore this total line
          else
            @other_incomes_after_tax.push cur_row
            if @other_income_after_tax.nil?
              @other_income_after_tax = nil_and_n_zeros(@gross_margin.length - 1)
            end
            #@other_income_after_tax = array_sum_FC(@other_income_after_tax, cur_row) # FIXME: this doesn't work for some reason...
            @other_income_after_tax = cur_row.zip(@other_income_after_tax).collect do |x,y|  
              if x.val.nil? and y.nil?
                nil
              elsif x.val.nil? and !y.nil?
                y
              elsif y.nil?
                x.val
              else
                x.val + y
              end
            end

          end

        when :done
          # ignore

        else
          @log.error("Income statement parser state machine.  Got into weird state, #{state}") if @log
          return false
        end

        if !next_state.nil?
          @log.debug("Income statement parser.  Switching to state: #{next_state}") if @log
          state = next_state
        end
      end

      if state != :done
        @log.warn("Balance sheet parser state machine.  Unexpected final state, #{state}") if @log
        return false
      end

      return true
    end

    def calculate_financing_income
      @re_financing_income = nil_and_n_zeros(@operating_revenue.length - 1)
      @re_operating_revenue = @operating_revenue
      @re_operating_expense = @operating_expense

      # look in revenues
      if @revenues != []
        @revenues.each do |r|
          if r[0].text.downcase =~ /interest income/
            @re_financing_income = array_sum_FC(@re_financing_income, r)
            @re_operating_revenue = array_diff_FC(@re_operating_revenue, r)
          end
        end
      end

      # look in operating expenses
      @operating_expenses.each do |e|
        if e[0].text.downcase =~ /interest expense/
          # FIXME: remove this from operating_expense
          @re_operating_expense = array_diff_FC(@re_operating_expense, e)

          # subtract this revenue from the financing income
          @re_financing_income = array_diff_FC(@re_financing_income, e)
        end
      end

      # look in other operating income
      @other_operating_incomes_before_tax.each do |i|
        if i[0].text.downcase =~ /(gain[s].* on.* securities|interest)/
          # FIXME: remove this from other_operating_income_before_tax

          # subtract this revenue from the financing income
          @re_financing_income = array_sum_FC(@re_financing_income, i)
        end
      end

      return true
    end

    def calculate_re_operating_income_from_sales_before_tax
      @re_gross_margin = array_diff_FF(@re_operating_revenue, @cost_of_revenue)
      @re_operating_income_from_sales_before_tax = array_diff_FF(@re_gross_margin, @re_operating_expense)

      return true
    end

    ############################################################################
    # Array helpers
    ############################################################################

    def nil_and_n_zeros(n)
      a = [nil]
      n.times { a.push(0.0) }
      return a
    end

    # param1: array of floats.  param2: array of SecEdgar::Cell
    def array_diff_FC(fs, cs)
      return fs.zip(cs).collect do |f, c|
        if f.nil? or c.val.nil?
          nil
        else
          f - c.val
        end
      end
    end

    # param1: array of floats.  param2: array of floats
    def array_diff_FF(f1s, f2s)
      return f1s.zip(f2s).collect do |f1, f2|
        if f1.nil? or f2.nil?
          nil
        else
          f1 - f2
        end
      end
    end

    # param1: array of floats.  param2: array of SecEdgar::Cell
    def array_sum_FC(fs, cs)
      return fs.zip(cs).collect do |f, c|
        if f.nil? and c.val.nil?
          nil
        elsif f.nil? and !c.val.nil?
          c.val
        elsif c.val.nil?
          f
        else
          f + c.val
        end
      end
    end

    # param1: array of floats.  param2: array of floats
    def array_sum_FF(f1s, f2s)
      return f1s.zip(f2s).collect do |f1, f2|
        if f1.nil? or f2.nil?
          nil
        else
          f1 + f2
        end
      end
    end

  end
    
end
