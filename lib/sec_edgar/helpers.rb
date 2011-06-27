module SecEdgar

  module Helpers

    def Helpers.get_all_10ks(ticker)
      rept_type = '10-K'
      download_path = "/tmp/"
      edgar = SecEdgar::Edgar.new
      
      reports = edgar.lookup_reports(ticker)
      reports.keep_if{ |r| r[:type] == rept_type }
      reports.sort! {|a,b| a[:date] <=> b[:date] }
      
      files = edgar.get_reports(reports, download_path)
      
      ten_k = SecEdgar::AnnualReport.new 
      ten_k.log = Logger.new('sec_edgar.log')
      ten_k.log.level = Logger::DEBUG
      ten_k.parse(files.shift)
      summary = ten_k.get_summary
      ten_k = nil
      
      while !files.empty?
        ten_k2 = SecEdgar::AnnualReport.new 
        ten_k2.log = Logger.new('sec_edgar.log')
        ten_k2.log.level = Logger::DEBUG
        ten_k2.parse(files.shift)
        summary2 = ten_k2.get_summary
      
        summary.merge(summary2)
      end

      return summary
    end

    def Helpers.get_shares_outstanding(ticker)
      std_quotes = YahooFinance::get_quotes(YahooFinance::StandardQuote, ticker)
      ext_quotes = YahooFinance::get_quotes(YahooFinance::ExtendedQuote, ticker)
    
      mkt_cap = Float(ext_quotes[ticker].marketCap.gsub(/[A-Za-z]/,''))
      case ext_quotes[ticker].marketCap.split('').last.upcase # last character indicates billions, millions, etc...
      when 'B'
        mkt_cap = mkt_cap * 1000.0 * 1000.0 * 1000.0
      when 'M'
        mkt_cap = mkt_cap * 1000.0 * 1000.0
      when 'K'
        mkt_cap = mkt_cap * 1000.0 
      else
        raise "unknown modifier"
      end
    
      share_price = Float(std_quotes[ticker].lastTrade)
    
      return mkt_cap / share_price
    end
    
    RISK_FREE_RATE = 0.0387
    EQUITY_RISK_PREMIUM = 0.084

    def Helpers.wacc_capm(r_f, r_m, beta)
      return r_f + ((beta*(r_m - r_f)))
    end

  end
end
