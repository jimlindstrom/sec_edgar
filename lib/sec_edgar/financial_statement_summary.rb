module SecEdgar

  class FinancialStatementSummary
    attr_accessor :report_dates

    # FIXME: all of this should be in a hash so that it can be more easily iterated over

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

    def initialize
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
      @ni_over_sales += fss2.fi_over_sales.values_at(*indices)

      @sales_over_noa += fss2.sales_over_noa.values_at(*indices)
      @revenue_growth += fss2.revenue_growth.values_at(*indices)
      @core_oi_growth += fss2.core_oi_growth.values_at(*indices)
      @oi_growth      += fss2.oi_growth.values_at(*indices)
      @fi_over_nfa    += fss2.fi_over_nfa.values_at(*indices)
      @re_oi          += fss2.re_oi.values_at(*indices)

    end

    def simple_valuation(g_1, g_2, g_long, rho_f)
      oi_0 = @oi_from_sales_after_tax.last
      oi_1 = oi_0 * (1.0 + g_1)

      v_noa_0 = oi_1 * (1.0 / (rho_f - 1.0)) * ((g_2 - g_long)/(rho_f - g_long))
      v_nfa_0 = @nfa.last
      v_e_0 = v_noa_0 + v_nfa_0

      return v_e_0
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

      end
    end

  end

end
