module SecEdgar

  class QuarterlyReport # this can also load an annual report
    attr_accessor :log, :bal_sheet, :inc_stmt
  
    def initialize
    end

    def get_summary
      fss = FinancialStatementSummary.new

      # make sure that the income statement and balance sheet have the same base_multiplier
      case @bal_sheet.base_multiplier  # FIXME: if we just converted the numbers up front, this would be a non-issue
        when 1000000
          bscale = Proc.new { |a| a.collect { |x| x*1000.0 } }
        when 1000
          bscale = Proc.new { |a| a }
        else
          raise TypeError, "unknown multiplier (#{@bal_sheet.base_multiplier})"
      end
      case @inc_stmt.base_multiplier
        when 1000000
          iscale = Proc.new { |a| a.collect { |x| x*1000.0 } }
        when 1000
          iscale = Proc.new { |a| a }
        else
          raise TypeError, "unknown multiplier (#{@bal_sheet.base_multiplier})"
      end

      # choose which indices to use (not all reports will the same set of dates, or be sorted
      # in the same direction.  Find common ones, then sort them ascending chronologically.)
      a = @bal_sheet.report_dates
      b = @inc_stmt.report_dates
      c = (a + b).sort.uniq.keep_if { |x| !a.index(x).nil? and !b.index(x).nil? }
      bsidx = c.collect { |x| a.index(x) } # indices of balance sheet columns
      isidx = c.collect { |x| b.index(x) } # indices of income statement columns

      if bsidx.empty? or isidx.empty?
        raise ParseError, "bal_sheet dates (#{a.join(',')}) don't overlap with inc_stmt dates (#{b.join(',')})" 
      end

      fss.report_dates = @bal_sheet.report_dates.values_at(*bsidx)

      fss.oa  = bscale.call(@bal_sheet.total_oa.cols.values_at(*bsidx))
      fss.ol  = bscale.call(@bal_sheet.total_ol.cols.values_at(*bsidx))
      fss.noa = bscale.call(@bal_sheet.noa.cols.values_at(*bsidx))
      fss.fa  = bscale.call(@bal_sheet.total_fa.cols.values_at(*bsidx))
      fss.fl  = bscale.call(@bal_sheet.total_fl.cols.values_at(*bsidx))
      fss.nfa = bscale.call(@bal_sheet.nfa.cols.values_at(*bsidx))
      fss.cse = bscale.call(@bal_sheet.cse.cols.values_at(*bsidx))

      fss.composition_ratio = @bal_sheet.noa.cols.values_at(*bsidx).zip(@bal_sheet.cse.cols.values_at(*bsidx)).collect { |x,y| x/y }
      fss.noa_growth = [nil] + calc_growth_rates(@bal_sheet.noa.cols.values_at(*bsidx))
      fss.cse_growth = [nil] + calc_growth_rates(@bal_sheet.cse.cols.values_at(*bsidx))

      fss.operating_revenue       = iscale.call(@inc_stmt.re_operating_revenue.cols.values_at(*isidx))
      fss.gross_margin            = iscale.call(@inc_stmt.re_gross_margin.cols.values_at(*isidx))
      fss.oi_from_sales_after_tax = iscale.call(@inc_stmt.re_operating_income_from_sales_after_tax.cols.values_at(*isidx))
      fss.oi_after_tax            = iscale.call(@inc_stmt.re_operating_income_after_tax.cols.values_at(*isidx))
      fss.financing_income        = iscale.call(@inc_stmt.re_net_financing_income_after_tax.cols.values_at(*isidx))
      fss.net_income              = iscale.call(@inc_stmt.re_net_income.cols.values_at(*isidx))

      fss.gm            = calc_ratios(@inc_stmt.re_gross_margin.cols.values_at(*isidx),                          @inc_stmt.re_operating_revenue.cols.values_at(*isidx))
      fss.sales_pm      = calc_ratios(@inc_stmt.re_operating_income_from_sales_after_tax.cols.values_at(*isidx), @inc_stmt.re_operating_revenue.cols.values_at(*isidx))
      fss.pm            = calc_ratios(@inc_stmt.re_operating_income_after_tax.cols.values_at(*isidx),            @inc_stmt.re_operating_revenue.cols.values_at(*isidx))
      fss.fi_over_sales = calc_ratios(@inc_stmt.re_net_financing_income_after_tax.cols.values_at(*isidx),        @inc_stmt.re_operating_revenue.cols.values_at(*isidx))
      fss.ni_over_sales = calc_ratios(@inc_stmt.re_net_income.cols.values_at(*isidx),                            @inc_stmt.re_operating_revenue.cols.values_at(*isidx))

      fss.sales_over_noa = calc_ratios(iscale.call(@inc_stmt.re_operating_revenue.cols.values_at(*isidx)), bscale.call(@bal_sheet.noa.cols.values_at(*bsidx)))
      fss.revenue_growth = [nil] + calc_growth_rates(@inc_stmt.re_operating_revenue.cols.values_at(*isidx))
      fss.core_oi_growth = [nil] + calc_growth_rates(@inc_stmt.re_operating_income_from_sales_after_tax.cols.values_at(*isidx))
      fss.oi_growth      = [nil] + calc_growth_rates(@inc_stmt.re_operating_income_after_tax.cols.values_at(*isidx))
      fss.fi_over_nfa    = calc_ratios(iscale.call(@inc_stmt.re_net_financing_income_after_tax.cols.values_at(*isidx)), bscale.call(@bal_sheet.nfa.cols.values_at(*bsidx)))
      fss.re_oi          = [nil] + calc_reois(iscale.call(@inc_stmt.re_operating_income_after_tax.cols.values_at(*isidx)), bscale.call(@bal_sheet.noa.cols.values_at(*bsidx)))

      return fss

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

      table_elems = doc.search("table")
      @bal_sheet = nil
      while !table_elems.empty?
        elem = table_elems.shift

        if @bal_sheet.nil? #and elem.innerHTML =~ /[Aa]sset/ # some simple filter so that we don't scan more tables than we need to
          @log.info("parsing balance sheet at next table") if @log
          @bal_sheet = BalanceSheet.new
          @bal_sheet.log = @log if @log

          if @bal_sheet.parse(elem) == false
            @log.info("failed to parse balance sheet, resetting to try again.") if @log
            @bal_sheet = nil # discard bogus parse attempts
          else
            @log.info("parsing of balance sheet succeeded") if @log
          end
        end

        if @inc_stmt.nil? and elem.innerHTML =~ /[Ii]ncome/ # some simple filter so that we don't scan more tables than we need to
          @log.info("parsing income statement at next table") if @log
          @inc_stmt = IncomeStatement.new
          @inc_stmt.log = @log if @log

          if @inc_stmt.parse(elem) == false
            @log.info("failed to parse income statement, resetting to try again.") if @log
            @inc_stmt = nil # discard bogus parse attempts
          else
            @log.info("parsing of income statement succeeded") if @log
          end
        end

      end

      raise ParseError, "Failed to parse balance sheet from #{filename}" if @bal_sheet.nil?
      @bal_sheet.validate

      raise ParseError, "Failed to parse income statement from #{filename}" if @inc_stmt.nil?
      @inc_stmt.validate

      return true
    end

    # Helpers for write_summary

    def calc_growth_rates(a)
      a[0..(a.length-2)].zip(a[1..a.length]).collect { |x,y| (Float(y)-x)/x }
    end

    def calc_ratios(a, b)
      a.zip(b).collect{ |x,y| Float(x)/y }
    end

    def calc_reois(ois, noas)
      ois[1..(ois.length-1)].zip(noas[0..(noas.length-2)]).collect { |oi,noa| Float(oi)-(0.1*noa) }
    end

  end
  
end
