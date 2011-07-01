module SecEdgar
  
  class BalanceSheet < FinancialStatement
    AR_ALLOWANCE_REGEX=/, net of allowance of ([$0-9,]+) and ([$0-9,]+)/
    STOCK_REGEX=/par value/
    NUMBER_REGEX=/[\$0-9,]+/
  
    # original values
    attr_accessor :assets, :liabs, :equity 
    attr_accessor :total_assets, :total_liabs, :total_equity 

    # reformulated values
    attr_accessor :operational_assets, :operational_liabs
    attr_accessor :financial_assets, :financial_liabs
    attr_accessor :common_equity 
    attr_accessor :total_oa, :total_fa, :total_ol, :total_fl
    attr_accessor :noa, :nfa, :cse

    def initialize
      super()
      @name = "Balance Sheet"

      @assets = []
      @liabs = []
      @equity = []
      @total_assets = nil
      @total_liabs = nil
      @total_equity = nil

      @operational_assets = []
      @operational_liabs = []
      @financial_assets = []
      @financial_liabs = []
      @common_equity = []
    end

    def parse(table_elem)
      # pull the table into rows (akin to CSV)
      return false if not super(table_elem)
  
      # pull apart assets, liabilities, equity (as originally stated)
      return false if not parse_assets_liabs_and_equity
      return false if not classify_assets
      return false if not classify_liabs
      return false if not classify_equity

      return true
    end

    ###########################################################################
    # calculate reformulated values (this needs to change)
    ###########################################################################

    def net_financial_assets(col_idx)
      return financial_assets(col_idx) - financial_liabs(col_idx)
    end

    def net_operational_assets(col_idx)
      return operational_assets(col_idx) - operational_liabs(col_idx)
    end

    def common_shareholders_equity(col_idx)
      return net_operational_assets(col_idx) + net_financial_assets(col_idx)
    end

    def validate
      super

      fail_if_equals("operational_assets", @operational_assets, nil)
      fail_if_equals("operational_liabs",  @operational_liabs,  nil)
      fail_if_equals("financial_assets",   @financial_assets,   nil)
      fail_if_equals("financial_liabs",    @financial_liabs,    nil)
      fail_if_equals("common_equity",      @common_equity,      nil)
      fail_if_equals("total_oa",           @total_oa,           nil)
      fail_if_equals("total_ol",           @total_ol,           nil)
      fail_if_equals("total_fa",           @total_fa,           nil)
      fail_if_equals("total_fl",           @total_fl,           nil)
      fail_if_equals("noa",                @noa,                nil)
      fail_if_equals("nfa",                @nfa,                nil)
      fail_if_equals("cse",                @cse,                nil)

      fail_if_doesnt_equal("noa.length",   @noa.cols.length,    @nfa.cols.length)
      fail_if_doesnt_equal("cse.length",   @cse.cols.length,    @noa.cols.length)
    end

  private

    ###########################################################################
    # Parsing
    ###########################################################################
  
    def parse_assets_liabs_and_equity
      state = :waiting_for_cur_assets
      @sheet.each do |row|
        @log.debug("  balance sheet parser.  Cur label: #{row.label}") if @log
        next_state = nil
        case state
        when :waiting_for_cur_assets
          if row.label.downcase =~ /current assets[:]*/
            next_state = :reading_current_assets
          elsif row.label != "" and !row.cols[0].nil? 
            # if the values have started and we didn't see 'current ...', assume this stmt doesn't break out cur/non-cur
            @log.info("balance sheet parser. this stmt doesn't break out current assets...") if @log
            next_state = :reading_non_current_assets
          end

        when :reading_current_assets
          if row.label.downcase =~ /total current assets/
            next_state = :reading_non_current_assets
          elsif row.label.downcase =~ /total cash.*/
            # don't save the totals line
          else
            row.flags[:current] = true
            @assets.push(row)
          end

        when :reading_non_current_assets
          if row.label.downcase =~ /total assets/
            next_state = :waiting_for_cur_liabs
            @total_assets = row
          elsif row.label.downcase == '' and !row.cols[0].nil? and !row.cols[1].nil? 
            # ... because, AMD 2003 10-k has a blank where you'd expect to see the total
            next_state = :waiting_for_cur_liabs
            @total_assets = row
          else
            row.flags[:non_current] = true
            @assets.push(row)
          end

        when :waiting_for_cur_liabs
          if row.label.downcase =~ /current liabilities[:]*/
            next_state = :reading_cur_liabs
          #elsif row.label.downcase =~ /^liabilities.*/ # in case they don't break out current ones
          #  next_state = :reading_non_current_liabilities
          #elsif row.label.downcase =~ /^total liabilities.*/ # in case they don't break out current ones
          elsif !row.cols[0].nil? # if the values have started and we didn't see 'current ...', assume this stmt doesn't break out cur/non-cur
            next_state = :reading_non_current_liabilities
          end

        when :reading_cur_liabs
          if row.label.downcase == "total current liabilities"
            next_state = :reading_non_current_liabilities
          else
            row.flags[:current] = true
            @liabs.push(row)
          end

        when :reading_non_current_liabilities
          if row.label.downcase =~ /(share|stock)holders.* equity:/
            next_state = :reading_shareholders_equity
          elsif row.label.downcase =~ /common stock/ 
            @equity.push(row)
            next_state = :reading_shareholders_equity
          elsif row.label.downcase =~ /total liab.*/
            # don't save the totals line
          else
            row.flags[:non_current] = true
            @liabs.push(row)
          end

        when :reading_shareholders_equity
          if row.label.downcase =~ /total.*(share|stock)holders.*equity/
            next_state = :done
            @total_equity = row
          else
            @equity.push(row)
          end

        when :done
          # FIXME: this should be a 2nd-to-last state and should THEN go to done...
          if row.label.downcase =~ /total liabilities and.*equity/
            @total_liabs = row.clone
            @total_liabs.subtract(@total_equity)
          elsif row.label.downcase == '' and !row.cols[0].nil? and !row.cols[1].nil? 
            # ... because, AMD 2003 10-k has a blank where you'd expect to see the total
            @total_liabs = row.clone
            @total_liabs.subtract(@total_equity)
          end

        else
          @log.error("Balance sheet parser state machine.  Got into weird state, #{state}") if @log
          return false
        end

        if !next_state.nil?
          @log.debug("  balance sheet parser.  Switching to state: #{next_state}") if @log
          state = next_state
        end
      end

      if state != :done
        @log.warn("Balance sheet parser state machine.  Unexpected final state, #{state}") if @log
        return false
      end

      return true
    end

    ###########################################################################
    # Classifiers for assets, liabilities, equity
    ###########################################################################

    def classify_assets
      ac = AssetClassifier.new

      @total_oa = SheetRow.new(@num_cols, 0.0)
      @total_fa = SheetRow.new(@num_cols, 0.0)
      @noa      = SheetRow.new(@num_cols, 0.0)
      @nfa      = SheetRow.new(@num_cols, 0.0)
      @assets.each do |a|
        if a.num_cols < 2
          @log.warn("asset must be 2 columns wide #{a.label}")
        else
          case ac.classify(a.label)[:class]
          when :oa
            @operational_assets.push(a)
            @total_oa.add(a)
            @noa.add(a)
          when :fa
            @financial_assets.push(a)
            @total_fa.add(a)
            @nfa.add(a)
          else
            raise TypeError, "Unknown class #{ac.classify(a.label)[:class]}"
          end
        end
      end
      return true
    end

    def classify_liabs
      lc = LiabClassifier.new

      @total_ol = SheetRow.new(@num_cols, 0.0)
      @total_fl = SheetRow.new(@num_cols, 0.0)
      @liabs.each do |l|
        if l.num_cols < 2
          @log.warn("liability must be 2 columns wide #{l}") if @log
        else
          case lc.classify(l.label)[:class]
          when :ol
            @operational_liabs.push(l)
            @total_ol.add(l)
            @noa.subtract(l)
          when :fl
            @financial_liabs.push(l)
            @total_fl.add(l)
            @nfa.subtract(l)
          else
            raise TypeError, "Unknown class #{lc.classify(l.label)[:class]}"
          end
        end
      end
      return true
    end

    def classify_equity
      ec = EquityClassifier.new

      @cse = SheetRow.new(@num_cols, 0.0)
      @equity.each do |e|
        if e.num_cols < 2
          @log.warn("equity must be 2 columns wide #{e}")
        else
          case ec.classify(e.label)[:class]
          when :pse
            @financial_liabs.push(e)
            @total_fl.add(e)
            @nfa.subtract(e)
          when :cse
            @common_equity.push(e)
            @cse.add(e)
          else
            raise TypeError, "Unknown class #{ec.classify(e.label)[:class]}"
          end
        end
      end
      return true
    end

  end
  
end
