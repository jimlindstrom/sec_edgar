module SecEdgar

  class FinancialStatementSummary
    attr_accessor :report_dates

    # balance sheet
    attr_accessor :oa, :ol, :noa
    attr_accessor :fa, :fl, :nfa
    attr_accessor :cse

    # Balance Sheet Analysis (FIXME: this should be calc'ed here, so that it can be merged)
    attr_accessor :composition_ratio
    attr_accessor :noa_growth
    attr_accessor :cse_growth

    # Income Statement
    attr_accessor :operating_revenue
    attr_accessor :gross_margin
    attr_accessor :oi_from_sales_after_tax
    attr_accessor :oi_after_tax
    attr_accessor :financing_income
    attr_accessor :net_income

    # Income Statement Margins (FIXME: this should be calc'ed here, so that it can be merged)
    attr_accessor :gm
    attr_accessor :sales_pm
    attr_accessor :pm
    attr_accessor :fi_over_sales
    attr_accessor :ni_over_sales

    # Income Statement Ratios (FIXME: this should be calc'ed here, so that it can be merged)
    attr_accessor :sales_over_noa # ATO
    attr_accessor :revenue_growth
    attr_accessor :core_oi_growth
    attr_accessor :oi_growth
    attr_accessor :fi_over_nfa
    attr_accessor :re_oi # ReOI (at 10%)

    attr_accessor :extra_csv_rows

    def initialize
      @extra_csv_rows = []
    end

    ###########################################################################
    # Validating sheets to see that they've been properly parsed
    ###########################################################################

    def fail_if_doesnt_equal(name_of_a, a, b, str=nil)
      if a.class == Float or b.class == Float
        pct_delta = ( a - b) / ( (a+b)/2 )
        if pct_delta > 0.01 or pct_delta < -0.01
          not_equal = true
        else
          not_equal = false
        end
      else
        not_equal = a != b
      end
      if not_equal
        msg = "#{@name} validation fail: #{name_of_a} (#{a}) != b (#{b})"
        @log.error(msg)
        @log.error("Note: #{str}") if !str.nil?
        filename = @name + String(Integer(Time.now.to_f))+".csv"
        @log.error("see #{filename}")
        write_to_csv(filename)
        raise ParseError, msg
      end
    end

    def fail_if_equals(name_of_a, a, b, str=nil)
      if a.class == Float or b.class == Float
        pct_delta = ( a - b) / ( (a+b)/2 )
        if pct_delta > 0.01 or pct_delta < -0.01
          equals = false
        else
          equals = true
        end
      else
        equals = a == b
      end
      if equals
        msg = "#{@name} validation fail: #{name_of_a} (#{a}) != b (#{b})"
        @log.error(msg)
        @log.error("Note: #{str}") if !str.nil?
        filename = @name + String(Integer(Time.now.to_f))+".csv"
        @log.error("see #{filename}")
        write_to_csv(filename)
        raise ParseError, msg
      end
    end

    def fail_if_less_than(name_of_a, a, b, str=nil)
      if a < b
        msg = "#{@name} validation fail: #{name_of_a} (#{a}) !< b (#{b})"
        @log.error(msg)
        @log.error("Note: #{str}") if !str.nil?
        filename = @name + String(Integer(Time.now.to_f))+".csv"
        @log.error("see #{filename}")
        write_to_csv(filename)
        raise ParseError, msg
      end
    end

    def fail_if_greater_than(name_of_a, a, b, str=nil)
      if a > b
        msg = "#{@name} validation fail: #{name_of_a} (#{a}) !> b (#{b})"
        @log.error(msg)
        @log.error("Note: #{str}") if !str.nil?
        filename = @name + String(Integer(Time.now.to_f))+".csv"
        @log.error("see #{filename}")
        write_to_csv(filename)
        raise ParseError, msg
      end
    end

    def validate
      # balance sheet validations
      fail_if_doesnt_equal("noa.length", @noa.length, @nfa.length)
      fail_if_doesnt_equal("noa.length", @noa.length, @cse.length)
      @noa.length.times do |idx|
        fail_if_doesnt_equal("cse[#{idx}]", @cse[idx], @noa[idx]+@nfa[idx])
      end

      # growth rate validations
      @noa_growth.length.times do |idx|
        if !@noa_growth[idx].nil?
          fail_if_less_than(   "@noa_growth[#{idx}]", @noa_growth[idx], -100) # -1000% growth
          fail_if_greater_than("@noa_growth[#{idx}]", @noa_growth[idx],  100) # +1000% growth
        end
      end
      @cse_growth.length.times do |idx|
        if !@cse_growth[idx].nil?
          fail_if_less_than(   "@cse_growth[#{idx}]", @cse_growth[idx], -100) # -1000% growth
          fail_if_greater_than("@cse_growth[#{idx}]", @cse_growth[idx],  100) # +1000% growth
        end
      end
      @revenue_growth.length.times do |idx|
        if !@revenue_growth[idx].nil?
          fail_if_less_than(   "@revenue_growth[#{idx}]", @revenue_growth[idx], -100) # -1000% growth
          fail_if_greater_than("@revenue_growth[#{idx}]", @revenue_growth[idx],  100) # +1000% growth
        end
      end
      @sales_over_noa.length.times do |idx|
        if !@sales_over_noa[idx].nil?
          fail_if_less_than(   "@sales_over_noa[#{idx}]", @sales_over_noa[idx], -100)
          fail_if_greater_than("@sales_over_noa[#{idx}]", @sales_over_noa[idx],  100)
        end
      end
    end

    def merge(fss2)

      # choose which indices to use (not all reports will the same set of dates, or be sorted
      # in the same direction.  Find common ones, then sort them ascending chronologically.)
      c = fss2.report_dates - @report_dates
      indices = c.collect { |x| fss2.report_dates.index(x) } # which indices to bring over

      @report_dates += fss2.report_dates.values_at(*indices)

      @oa  += fss2.oa.values_at(*indices)
      @ol  += fss2.ol.values_at(*indices)
      @noa += fss2.noa.values_at(*indices)
      @fa  += fss2.fa.values_at(*indices)
      @fl  += fss2.fl.values_at(*indices)
      @nfa += fss2.nfa.values_at(*indices)
      @cse += fss2.cse.values_at(*indices)

      @composition_ratio += fss2.composition_ratio.values_at(*indices)
      @noa_growth        += fss2.noa_growth.values_at(*indices)
      @cse_growth        += fss2.cse_growth.values_at(*indices)

      @operating_revenue       += fss2.operating_revenue.values_at(*indices)
      @gross_margin            += fss2.gross_margin.values_at(*indices)
      @oi_from_sales_after_tax += fss2.oi_from_sales_after_tax.values_at(*indices)
      @oi_after_tax            += fss2.oi_after_tax.values_at(*indices)
      @financing_income        += fss2.financing_income.values_at(*indices)
      @net_income              += fss2.net_income.values_at(*indices)

      @gm            += fss2.gm.values_at(*indices)
      @sales_pm      += fss2.sales_pm.values_at(*indices)
      @pm            += fss2.pm.values_at(*indices)
      @fi_over_sales += fss2.fi_over_sales.values_at(*indices)
      @ni_over_sales += fss2.ni_over_sales.values_at(*indices)

      @sales_over_noa += fss2.sales_over_noa.values_at(*indices)
      @revenue_growth += fss2.revenue_growth.values_at(*indices)
      @core_oi_growth += fss2.core_oi_growth.values_at(*indices)
      @oi_growth      += fss2.oi_growth.values_at(*indices)
      @fi_over_nfa    += fss2.fi_over_nfa.values_at(*indices)
      @re_oi          += fss2.re_oi.values_at(*indices)

    end

    def write_to_yaml(filename) # FIXME: This isn't technically yaml...
      fh = File.open(filename, "w")
      fh.puts(@report_dates.to_s)
      fh.puts(@oa.to_s)
      fh.puts(@ol.to_s)
      fh.puts(@noa.to_s)
      fh.puts(@fa.to_s)
      fh.puts(@fl.to_s)
      fh.puts(@nfa.to_s)
      fh.puts(@cse.to_s)
      fh.puts(@composition_ratio.to_s)
      fh.puts(@noa_growth.to_s)
      fh.puts(@cse_growth.to_s)
      fh.puts(@operating_revenue.to_s)
      fh.puts(@gross_margin.to_s)
      fh.puts(@oi_from_sales_after_tax.to_s)
      fh.puts(@oi_after_tax.to_s)
      fh.puts(@financing_income.to_s)
      fh.puts(@net_income.to_s)
      fh.puts(@gm.to_s)
      fh.puts(@sales_pm.to_s)
      fh.puts(@pm.to_s)
      fh.puts(@fi_over_sales.to_s)
      fh.puts(@ni_over_sales.to_s)
      fh.puts(@sales_over_noa.to_s)
      fh.puts(@revenue_growth.to_s)
      fh.puts(@core_oi_growth.to_s)
      fh.puts(@oi_growth.to_s)
      fh.puts(@fi_over_nfa.to_s)
      fh.puts(@re_oi.to_s)
      fh.close
    end

    def read_from_yaml(filename)
      fh = File.open(filename, "r")
      @report_dates = eval fh.gets
      @oa = eval fh.gets
      @ol = eval fh.gets
      @noa = eval fh.gets
      @fa = eval fh.gets
      @fl = eval fh.gets
      @nfa = eval fh.gets
      @cse = eval fh.gets
      @composition_ratio = eval fh.gets
      @noa_growth = eval fh.gets
      @cse_growth = eval fh.gets
      @operating_revenue = eval fh.gets
      @gross_margin = eval fh.gets
      @oi_from_sales_after_tax = eval fh.gets
      @oi_after_tax = eval fh.gets
      @financing_income = eval fh.gets
      @net_income = eval fh.gets
      @gm = eval fh.gets
      @sales_pm = eval fh.gets
      @pm = eval fh.gets
      @fi_over_sales = eval fh.gets
      @ni_over_sales = eval fh.gets
      @sales_over_noa = eval fh.gets
      @revenue_growth = eval fh.gets
      @core_oi_growth = eval fh.gets
      @oi_growth = eval fh.gets
      @fi_over_nfa = eval fh.gets
      @re_oi = eval fh.gets
      fh.close
    end

    def to_csv(filename)

      CSV.open(filename, "wb") do |csv|
        csv << ["Ammounts in 1,000s"]
        csv << [""] + @report_dates
        csv << [""]

        csv << ["Balance Sheet"]
        csv << ["  NOA"  ]
        csv << ["    OA" ] + @oa
        csv << ["    OL" ] + @ol
        csv << ["    NOA"] + @noa
        csv << ["  NFA"  ]
        csv << ["    FA" ] + @fa
        csv << ["    FL" ] + @fl
        csv << ["    NFA"] + @nfa
        csv << ["  CSE"  ]
        csv << ["    CSE"] + @cse
        csv << [""]

        csv << ["Balance Sheet Analysis"]
        csv << ["  Composition ratio"   ] + @composition_ratio
        csv << ["  NOA growth",         ] + @noa_growth
        csv << ["  CSE growth",         ] + @cse_growth
        csv << [""]

        csv << ["Income Statement"]
        csv << ["  Operating revenues"       ] + @operating_revenue
        csv << ["  Gross margin"             ] + @gross_margin
        csv << ["  OI from sales (after tax)"] + @oi_from_sales_after_tax
        csv << ["  OI (after tax)"           ] + @oi_after_tax
        csv << ["  Financing income"         ] + @financing_income
        csv << ["  Net income"               ] + @net_income
        csv << [""]

        csv << ["Income Statement Margin Analysis"]
        csv << ["  Gross margin"] + @gm
        csv << ["  Sales PM"    ] + @sales_pm
        csv << ["  PM"          ] + @pm
        csv << ["  FI / Sales"  ] + @fi_over_sales
        csv << ["  NI / Sales"  ] + @ni_over_sales
        csv << [""]

        csv << ["Income Statement Ratio Analysis"]
        csv << ["  Sales / NOA (ATO)"] + @sales_over_noa
        csv << ["  Revenue Growth",  ] + @revenue_growth
        csv << ["  Core OI Growth",  ] + @core_oi_growth
        csv << ["  OI Growth",       ] + @oi_growth
        csv << ["  FI / NFA",        ] + @fi_over_nfa
        csv << ["  ReOI (at 10%)",   ] + @re_oi
        csv << [""]

        @extra_csv_rows.each do |row|
          csv << row
        end

      end
    end

  end

end
