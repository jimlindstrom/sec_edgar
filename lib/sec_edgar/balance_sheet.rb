module SecEdgar
  
  class BalanceSheet < FinancialStatement
    AR_ALLOWANCE_REGEX=/, net of allowance of ([$0-9,]+) and ([$0-9,]+)/
    STOCK_REGEX=/par value/
    NUMBER_REGEX=/[\$0-9,]+/
  
    def initialize
      super()
      @name = "Balance Sheet"
    end
    def parse(edgar_fin_stmt)
      ret = super(edgar_fin_stmt)
      return false if ret == false
  
      # parse the common stock line
      @rows.each_with_index do |row, idx|
        if String(row[0]).match(STOCK_REGEX) and
           String(row[1]).match(STOCK_REGEX) then
          @rows[idx].delete_at(0)
          @rows[idx].delete_at(0)
          @rows[idx].insert(0,"Common or Preferred Stock")
  
        elsif String(row[0]).match(STOCK_REGEX)  and
              String(row[1]).match(NUMBER_REGEX) and
              String(row[2]).match(STOCK_REGEX)  and
              String(row[3]).match(NUMBER_REGEX) then
          @rows[idx].delete_at(0)
          @rows[idx].insert(0,"Common or Preferred Stock")
          @rows[idx].delete_at(2)
          @rows[idx].insert(2,"Common or Preferred Stock")
  
        elsif String(row[0]).match(STOCK_REGEX)
          @rows[idx].delete_at(0)
          @rows[idx].insert(0,"Common or Preferred Stock")
        end
      end
  
      # pull out the date ranges
      @rows.each_with_index do |row, idx|
        # Match [][As of Dec 31, 2003][As of Dec 31, 2004]
        if String(row[0]).match(/As[^A-Za-z]*of/) and
           String(row[1]).match(/As[^A-Za-z]*of/) then
          @rows[idx][0].gsub!(/As[^A-Za-z]*of[^A-Za-z]*/,'')
          @rows[idx][1].gsub!(/As[^A-Za-z]*of[^A-Za-z]*/,'')
          @rows[idx].insert(0,"As of")
          @rows[idx].delete_at(3)
  
        # Match [As of][][]
        #       [2003][2004][]
        elsif String(row[0]).match(/As[^A-Za-z]*of/) and
              String(@rows[idx+1][0]).match(/[0-9]+/) and
              String(@rows[idx+1][1]).match(/[0-9]+/) then
          @rows[idx].concat(@rows[idx+1])
          @rows.delete_at(idx+1)
  
        # Match [December 31][][]
        #       [2003][2004][]
        elsif String(row[0]).match(/[A-Za-z]+[^A-Za-z]+[0-9]+/) and
              String(@rows[idx+1][0]).match(/[0-9]+/) and
              String(@rows[idx+1][1]).match(/[0-9]+/) then
          @rows[idx].concat(@rows[idx+1])
          @rows.delete_at(idx+1)
        end
      end
  
      # pull out the A/R allowances
      @rows.each_with_index do |row, index|
        if String(row[0]).match(AR_ALLOWANCE_REGEX)
          # first, (FIXME) pull out the allowances from the regex
          allowances = [$1, $2]
          allowances.map!{|item| item.gsub(/[$,]/,"")} # strip out comma and dollar sign
          allowances_row=["A/R Allowance"].concat(allowances)
  
          # now remove the allowances from the current line
          row[0] = row[0].gsub(AR_ALLOWANCE_REGEX,', net of allowance')
          @rows[index] = row
          @rows[index+1] = allowances_row
        end
      end

      return true
  
    end
  end
  
end
