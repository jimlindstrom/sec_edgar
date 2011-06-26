module SecEdgar

  class FinancialStatementSummary
    attr_accessor :report_dates

    # balance sheet
    attr_accessor :oa, :ol, :noa
    attr_accessor :fa, :fl, :nfa
    attr_accessor :cse

    # Balance Sheet Analysis
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

    # Income Statement Margins
    attr_accessor :gm
    attr_accessor :sales_pm
    attr_accessor :pm
    attr_accessor :fi_over_sales
    attr_accessor :ni_over_sales

    # Income Statement Ratios
    attr_accessor :sales_over_noa # ATO
    attr_accessor :revenue_growth
    attr_accessor :core_oi_growth
    attr_accessor :oi_growth
    attr_accessor :fi_over_nfa
    attr_accessor :re_oi # ReOI (at 10%)

    def initialize
    end

    def simple_valuation(g_1, g_2, g_long, rho_f)
      oi_0 = @oi_from_sales_after_tax.last
      oi_1 = oi_0 * (1.0 + g_1)

      v_noa_0 = oi_1 * (1.0 / (rho_f - 1.0)) * ((g_2 - g_long)/(rho_f - g_long))
      v_nfa_0 = @nfa.last
      v_e_0 = v_noa_0 + v_nfa_0

      return v_e_0
    end

    def write_summary(filename)

      CSV.open(filename, "wb") do |csv|
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
