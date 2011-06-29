class String
    def remove_non_ascii(replacement="")
        self.gsub(/[\u0080-\u00ff]/,replacement)
    end
end

module SecEdgar

  class ParseError < Exception
  end

  class EdgarCache
    PAGE_CACHE_FOLDER = '/Users/jimlindstrom/code/sec_edgar/pagecache/'

    def initialize
    end

    # FIXME: this assumes that 

    def exists?(key)
      return FileTest.exists?(key_to_cache_filename(key))
    end

    def insert(key, value)
      fh = File.open(key_to_cache_filename(key), "w")
      fh.write(value)
      fh.close
    end

    def lookup(key)
      fh = File.open(key_to_cache_filename(key), "r")
      value = fh.read
      fh.close
      return value
    end

    def key_to_cache_filename(key)
      return PAGE_CACHE_FOLDER + Digest::SHA1.hexdigest(key) + ".html"
    end

  end

  class Edgar
    AGENT_ALIAS = 'Windows IE 7'
    PAGE_CACHE_FOLDER = '/Users/jimlindstrom/code/sec_edgar/pagecache/'

    attr_accessor :log
    
    def initialize
      @agent = nil
      @cache = EdgarCache.new
    end
      
    def good_ticker?(ticker)
      # first search for the company in question
      agent = create_agent
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      
      # if there's a form, it's a good ticker
      form  = page.forms.first

      return !form.nil?
    end
    
    def get_fin_stmts(ticker, save_folder)
      return nil if not good_ticker?(ticker)

      reports  = get_10q_reports(ticker, save_folder)
      reports += get_10k_reports(ticker, save_folder)
      return reports
    end

    def get_10q_reports(ticker, save_folder)
      reports = []

      @log.info("Getting 10q reports for #{ticker}") if @log
      files = download_10q_reports(ticker, save_folder)
      return nil if files.nil?
      files.each do |cur_file|
        cur_ten_q = QuarterlyReport.new { |q| q.log = @log }
        cur_ten_q.parse(cur_file)

        reports.push cur_ten_q
      end
      return reports
    end

    def get_10k_reports(ticker, save_folder)
      reports = []

      @log.info("Getting 10k reports for #{ticker}") if @log
      files = download_10k_reports(ticker, save_folder)
      return nil if files.nil?
      files.each do |cur_file|
        cur_ten_k = AnnualReport.new { |a| a.log = @log }
        cur_ten_k.parse(cur_file)

        reports.push cur_ten_k
      end
      return reports
    end

    # returns list of files downloaded
    # returns nil if bad ticker
    def download_10q_reports(ticker, save_folder)
      @log.info("Downloading 10q reports for #{ticker}") if @log
      return nil if not good_ticker?(ticker)

      reports = lookup_reports(ticker)
      return nil if reports.nil?
      reports.keep_if { |r| r[:type]=='10-Q' }

      report_files = get_reports(reports, save_folder)
      return report_files
    end
 
    # returns list of files downloaded
    # returns nil if bad ticker
    def download_10k_reports(ticker, save_folder)
      @log.info("Downloading 10k reports for #{ticker}") if @log
      if !good_ticker?(ticker)
        @log.error("#{ticker} is not a good ticker") if @log
        return nil
      end

      reports = lookup_reports(ticker)
      return nil if reports.nil?
      reports.keep_if { |r| r[:type]=='10-K' }

      report_files = get_reports(reports, save_folder)
      return report_files
    end
    
    def lookup_reports(ticker)
      @log.info("Looking up reports for #{ticker}") if @log
      if !good_ticker?(ticker)
        @log.error("#{ticker} is not a good ticker") if @log
        return nil
      end

      # first search for the company in question
      agent = create_agent
      page  = agent.get('http://www.sec.gov/edgar/searchedgar/companysearch.html')
      form  = page.forms.first
      form['CIK'] = ticker
      page = form.submit
      return nil if page.nil?

      reports = [ ]

      while !page.nil?
        doc = Hpricot(page.body)
        trs = doc.search("table[@summary='Results']/tr")
        trs.shift # ignore the header row
        trs.each do |tr_item|
          tds = tr_item.search("td")
  
          reports.push( { :type => tds[0].innerHTML,
                          :url  => tds[1].children.first.attributes['href'],
                          :date => tds[3].innerHTML } )
        end
  
        buttons = doc.search("input[@value='Next 40']")
        if buttons.length > 0
          button = buttons.first
          next_url = button.attributes['onclick'].gsub(/^[^']*'/,'').gsub(/'$/,'')
          page = agent.get('http://www.sec.gov' + next_url)
        else
          page = nil
        end
      end

      return reports
    end

    def get_reports(reports, save_folder)
      @log.info("Getting reports") if @log
      files = []

      rept_type_linktext =
        { "10-Q" => "d10q.htm",
          "10-K" => "d10k.htm" }

      # for each report index
      reports.each do |report|
        raise TypeError, "unsupported report type #{report[:type]}" if !rept_type_linktext.keys.include?(report[:type])

        cur_file = get_single_report(report, save_folder)
        files.push cur_file if !cur_file.nil?
      end
  
      return files
    end

  private

    def get_single_report(report, save_folder)

      # check whether the page is already retrieved, in the cache
      if @cache.exists?(report[:url])
        return @cache.key_to_cache_filename(report[:url])
      end

      # page wasn't in the cache, so retrieve it
      cur_filename = get_single_report_from_scratch(report, save_folder)

      # insert the page into the cache
      if !cur_filename.nil?
        fh = File.open(cur_filename, "r") 
        @cache.insert(report[:url], fh.read)
        fh.close
      end

      return cur_filename

    end

    def get_single_report_from_scratch(report, save_folder)

      agent = create_agent
      page = agent.get('http://www.sec.gov' + report[:url])
      doc = Hpricot(page.body)

      trs = doc.search("table[@class='tableFile']/tr")
      trs.each do |tr_item|

        tds = tr_item.search("td")
        if !tds[3].nil? and tds[3].innerHTML == report[:type]
          subpage_url ='http://www.sec.gov' + tds[2].children.first.attributes['href']
          if subpage_url =~ /htm$/
            subpage = agent.get(subpage_url)
  
            cur_filename = save_folder + report[:date] + ".html"
  
            fh = File.open(cur_filename, "w") 
            fh << subpage.body
            fh.close

            return cur_filename
          end
        end

      end

      return nil
    end
       
    def create_agent
      return @agent if not @agent.nil?

      @agent = Mechanize.new # { |a| a.log = Logger.new('mech.log') }
      @agent.user_agent_alias = AGENT_ALIAS
      @agent.redirection_limit= 5
      return @agent
    end

  end
  
end
