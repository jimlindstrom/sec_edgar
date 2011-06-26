class String
    def remove_non_ascii(replacement="")
        self.gsub(/[\u0080-\u00ff]/,replacement)
    end
end

module SecEdgar

  class Edgar
    AGENT_ALIAS = 'Windows IE 7'

    attr_accessor :log
    
    def initialize
      @agent = nil
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
      agent = create_agent
      reports.each do |report|
        raise "unsupported report type #{report[:type]}" if !rept_type_linktext.keys.include?(report[:type])

        page = agent.get('http://www.sec.gov' + report[:url])
        page.links.each do |link|
          if link.text == rept_type_linktext[report[:type]]
            subpage = agent.get('http://www.sec.gov' + link.href)

            cur_filename = save_folder + report[:date] + ".html"
            files.push cur_filename

            fh = File.open(cur_filename, "w") 
            fh << subpage.body
            fh.close
          end
        end
      end

      return files
    end

  private
       
    def create_agent
      return @agent if not @agent.nil?

      @agent = Mechanize.new # { |a| a.log = Logger.new('mech.log') }
      @agent.user_agent_alias = AGENT_ALIAS
      @agent.redirection_limit= 5
      return @agent
    end

    # Takes in something like "January 2, 2008" and returns 2008_01_02
    def parse_date_string(date_str)

      if date_str =~ /([0-9]+)\/([0-9]+)\/([0-9]{4})/
        $mon  = $1
        $day  = $2
        $year = $3

        # construct return string
        $ret_str = $year + "_" + $mon + "_" + $day
      elsif date_str.match(/([A-Za-z]+) ([0-9]+), ([0-9]+)/)
        $mon  = $1
        $day  = $2
        $year = $3
    
        # convert the month name to a number
        $months = ["january","february","march","april","may","june","july","august","september","october","november","december"]
        $mon  = String($months.index{|x| x==$mon.downcase} + 1)
    
        # zero-pad the day and month to 2 digits
        if $mon.length < 2
          $mon = "0" + $mon
        end
        if $day.length < 2
          $day = "0" + $day
        end
    
        # construct return string
        $ret_str = $year + "_" + $mon + "_" + $day
      else
        raise "Unrecognizable date string: #{date_str}"
      end

      return $ret_str
    end


  end
  
end
