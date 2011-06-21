module SecEdgar

  class IncomeStatement < FinancialStatement
    def initialize
      super()
      @name = "Income Statement"
    end
    def parse(edgar_fin_stmt)
      super(edgar_fin_stmt)
  
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
  
      # FIXME: get rid of empty lines
      # FIXME: pull out all the stock-based compensation expenses
    end
  end
  
end
