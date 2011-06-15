module SecEdgar

  class CashFlowStatement < FinancialStatement
    def initialize
      super()
      @name = "Cash Flow Statement"
    end
    def parse(edgar_fin_stmt)
      super(edgar_fin_stmt)
  
      # pull out the date ranges
      @rows.each_with_index do |row, idx|
        # Match [Month Ended]
        #       [Mar 1, 2003][Mar 1, 2004]
        if String(row[0]).match(/[Mm]onth.*[Ee]nded/) then
          if row.length < 2
            @rows[idx].concat(@rows[idx+1])
            @rows.delete_at(idx+1)
          end
  
        # Match [Year Ended]
        #       [Mar 1, 2003][Mar 1, 2004]
        elsif String(row[0]).match(/[Yy]ear.*[Ee]nded/) then
          if row.length < 2
            @rows[idx].concat(@rows[idx+1])
            @rows.delete_at(idx+1)
          end
        end
      end
    end
  end
  
end
