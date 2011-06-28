module SecEdgar

  class IncomeStatement < FinancialStatement
    TAX_RATE = 0.35

    attr_accessor :operating_revenue, :cost_of_revenue, :gross_margin
    attr_accessor :operating_expense, :operating_income_from_sales_before_tax
    attr_accessor :other_operating_income_before_tax, :operating_income_before_tax
    attr_accessor :provision_for_tax, :operating_income_after_tax
    attr_accessor :other_income_after_tax, :net_income

    attr_accessor :re_financing_income, :re_operating_revenue, :re_gross_margin
    attr_accessor :re_operating_expense, :re_operating_income_from_sales_before_tax
    attr_accessor :re_other_operating_income_before_tax
    attr_accessor :re_operating_income_from_sales_after_tax
    attr_accessor :re_operating_income_after_tax, :re_net_financing_income_after_tax
    attr_accessor :re_net_income

    def initialize
      super()
      @name = "Income Statement"

      @revenues                           = []
      @operating_expenses                 = []
      @other_operating_incomes_before_tax = []
      @other_incomes_after_tax            = []
      @other_operating_income_before_tax  = nil
      @other_income_after_tax             = nil
    end

    def parse(edgar_fin_stmt)
      # pull the table into rows (akin to CSV)
      return false if not super(edgar_fin_stmt)

      # pull out the basic statement
      return false if not parse_income_stmt_state_machine

      # restate it
      return false if not calculate_financing_income
      return false if not calculate_re_operating_income_from_sales_before_tax
      return false if not calculate_re_operating_income_from_sales_after_tax
      return false if not calculate_re_operating_income_after_tax
      return false if not calculate_re_net_financing_income_after_tax
      return false if not calculate_re_net_income
    end

    def validate
      super

      fail_if_equals("re_financing_income",                       @re_financing_income,                       nil)
      fail_if_equals("re_operating_revenue",                      @re_operating_revenue,                      nil)
      fail_if_equals("re_gross_margin",                           @re_gross_margin,                           nil)
      fail_if_equals("re_operating_expense",                      @re_operating_expense,                      nil)
      fail_if_equals("re_operating_income_from_sales_before_tax", @re_operating_income_from_sales_before_tax, nil)
      fail_if_equals("re_other_operating_income_before_tax",      @re_other_operating_income_before_tax,      nil)
      fail_if_equals("re_operating_income_from_sales_after_tax",  @re_operating_income_from_sales_after_tax,  nil)
      fail_if_equals("re_operating_income_after_tax",             @re_operating_income_after_tax,             nil)
      fail_if_equals("re_net_financing_income_after_tax",         @re_net_financing_income_after_tax,         nil)
      fail_if_equals("re_net_income",                             @re_net_income,                             nil)
    end

  private

    def parse_income_stmt_state_machine
      
      state = :waiting_for_revenues
      @sheet.each do |row|
        @log.debug("income statement parser.  Cur label: #{row.label}") if @log
        next_state = nil
        case state
        when :waiting_for_revenues
          if row.label.downcase =~ /(net sales|net revenue|revenue)/
            if row.cols[0].nil? #  there's a list of individual revenue line items cominng
              next_state = :reading_revenues
            else # there's no lst of revenues coming, just the total on this line
              @operating_revenue = row
              next_state = :reading_cost_of_revenue
            end
          else
            # ignore
          end

        when :reading_revenues
          if row.label.downcase =~ /total/
            @operating_revenue = row
            next_state = :reading_cost_of_revenue
          else
            @revenues.push row
          end

        when :reading_cost_of_revenue
          if row.label.downcase =~ /cost of (revenue|sales)/ and !row.cols[0].nil?
            @cost_of_revenue = row
            @gross_margin = @operating_revenue.clone
            @gross_margin.subtract(@cost_of_revenue)
            next_state = :reading_operating_expenses
            @operating_expense = SheetRow.new(@num_cols, 0.0)
          end

        when :reading_operating_expenses
          if ( row.label.downcase =~ /(^total|^operating expense[s]*$)/ ) or
             ( ( row.label == "" ) and !row.cols[0].nil? and !row.cols[1].nil? ) # AMD 2003 10-K has blank instead of the total
            @operating_income_from_sales_before_tax = @gross_margin.clone
            @operating_income_from_sales_before_tax.subtract(@operating_expense)
            next_state = :reading_other_operating_expenses_before_tax
          elsif row.label.downcase =~ /gross margin/
            # ignore
          elsif row.label.downcase =~ /gross profit/
            # ignore
          else
            @operating_expenses.push row
            @operating_expense.add(row)
          end

        when :reading_other_operating_expenses_before_tax
          if row.label.downcase =~ /provision.*for [income ]*tax/
            @other_operating_income_before_tax = SheetRow.new(@num_cols, 0.0) if @other_operating_income_before_tax.nil?

            @operating_income_before_tax = @operating_income_from_sales_before_tax.clone
            @operating_income_before_tax.add(@other_operating_income_before_tax) 

            @provision_for_tax = row

            @operating_income_after_tax = @operating_income_before_tax.clone
            @operating_income_after_tax.subtract(@provision_for_tax)

            next_state = :reading_other_incomes_after_tax

          elsif row.label.downcase =~ /(operating income|^income.*before.*tax|income from operations)/
            # ignore this total line

          else
            @other_operating_incomes_before_tax.push row

            @other_operating_income_before_tax = SheetRow.new(@num_cols, 0.0) if @other_operating_income_before_tax.nil?
            @other_operating_income_before_tax.add(row)

          end

        when :reading_other_incomes_after_tax
          if row.label.downcase =~ /net income/
            @other_income_after_tax = SheetRow.new(@num_cols, nil) if @other_income_after_tax.nil?
            @net_income = @operating_income_after_tax.clone  ### FIXME: THIS SECTION SEEMS WRONG
            @net_income.add(@other_income_after_tax)
            next_state = :done
          elsif row.label.downcase =~ /(^income of consolidated group$|^total$)/
            # ignore this total line
          else
            @other_incomes_after_tax.push row
            if @other_income_after_tax.nil?
              @other_income_after_tax = SheetRow.new(@num_cols, 0.0)
            end
            @other_income_after_tax.add(row)
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
        @log.warn("Income statement parser state machine.  Unexpected final state, #{state}") if @log
        return false
      end

      return true
    end

    def calculate_financing_income
      @re_financing_income = SheetRow.new(@num_cols, 0.0)
      @re_operating_revenue = @operating_revenue.clone
      @re_operating_expense = @operating_expense.clone
      @re_other_operating_income_before_tax = @other_operating_income_before_tax.clone

      if @revenues != []
        @revenues.each do |r|
          if r.label.downcase =~ /interest income/
            @re_financing_income.add(r)
            @re_operating_revenue.subtract(r)
          end
        end
      end

      @operating_expenses.each do |e|
        if e.label.downcase =~ /interest expense/
          @re_operating_expense.subtract(e)
          @re_financing_income.subtract(e)
        end
      end

      @other_operating_incomes_before_tax.each do |i|
        if i.label.downcase =~ /(gain[s].* on.* securities|interest)/
          @re_other_operating_income_before_tax.subtract(i)
          @re_financing_income.add(i)
        end
      end

      return true
    end

    def calculate_re_operating_income_from_sales_before_tax
      @re_gross_margin = re_operating_revenue.clone
      @re_gross_margin.subtract(@cost_of_revenue)

      @re_operating_income_from_sales_before_tax = @re_gross_margin.clone
      @re_operating_income_from_sales_before_tax.subtract(@re_operating_expense)

      return true
    end

    def calculate_re_operating_income_from_sales_after_tax
      non_sales_income = @re_other_operating_income_before_tax.clone
      non_sales_income.add(@re_financing_income)

      tax_on_non_sales_income = non_sales_income.clone
      tax_on_non_sales_income.multiply_by(TAX_RATE)

      tax_on_sales_income = @provision_for_tax.clone
      tax_on_sales_income.subtract(tax_on_non_sales_income)

      @re_operating_income_from_sales_after_tax = @re_operating_income_from_sales_before_tax.clone
      @re_operating_income_from_sales_after_tax.subtract(tax_on_sales_income)

      return true
    end

    def calculate_re_operating_income_after_tax
      tax_on_other_operating_income = @re_other_operating_income_before_tax.clone
      tax_on_other_operating_income.multiply_by(TAX_RATE)

      @re_operating_income_after_tax = @re_other_operating_income_before_tax.clone
      @re_operating_income_after_tax.subtract(tax_on_other_operating_income)
      @re_operating_income_after_tax.add(@other_income_after_tax)
      @re_operating_income_after_tax.add(@re_operating_income_from_sales_after_tax)

      return true
    end

    def calculate_re_net_financing_income_after_tax
      @re_net_financing_income_after_tax = @re_financing_income.clone
      @re_net_financing_income_after_tax.multiply_by(1 - TAX_RATE)
      # ignores after-tax financing income (which we haven't seen in any test vectors yet)

      return true
    end

    def calculate_re_net_income
      @re_net_income = @re_net_financing_income_after_tax.clone
      @re_net_income.add(@re_operating_income_after_tax)

      return true
    end

  end
    
end
