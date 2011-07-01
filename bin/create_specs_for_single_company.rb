#!/usr/bin/env ruby

if ARGV.length < 1
  puts "Usage: ./bin/create_specs_for_single_company.rb <ticker>"
  exit 0
end
ticker = ARGV[0]


spec_file = "/tmp/sec_edgar_parsing_spec.rb"
fh = File.open(spec_file, "w")

fh.write("# sec_edgar_parsing_spec.rb\n")
fh.write("\n")
fh.write("$LOAD_PATH << './lib'\n")
fh.write("require 'sec_edgar'\n")
fh.write("\n")
fh.write("\n")
fh.write("def test_fn(ticker)\n")
fh.write("  rept_type = '10-K'\n")
fh.write("  download_path = '/tmp/'\n")
fh.write("  edgar = SecEdgar::Edgar.new\n")
fh.write("\n")
fh.write("  reports = edgar.lookup_reports(ticker)\n")
fh.write("  if !reports.nil? and !reports.empty?\n")
fh.write("    reports.keep_if{ |r| r[:type] == rept_type }\n")
fh.write("    reports.sort! {|a,b| a[:date] <=> b[:date] }\n")
fh.write("    reports.keep_if{ |r| ['2008','2009','2010','2011'].include?(r[:date].gsub(/-.*/,'')) }\n")
fh.write("    if !reports.nil? and !reports.empty?\n")
fh.write("      \n")
fh.write("      files = edgar.get_reports(reports, download_path)\n")
fh.write("      if !files.nil? and !files.empty?\n")
fh.write("        \n")
fh.write("        summary = nil\n")
fh.write("        while summary == nil and !files.empty?\n")
fh.write("          ten_k = SecEdgar::AnnualReport.new \n")
fh.write("          ten_k.log = Logger.new('sec_edgar.log')\n")
fh.write("          ten_k.log.level = Logger::DEBUG\n")
fh.write("          cur_file = files.shift\n")
fh.write("          ten_k.parse(cur_file)\n")
fh.write("          summary = ten_k.get_summary\n")
fh.write("        end\n")
fh.write("        \n")
fh.write("        while !files.empty?\n")
fh.write("          ten_k2 = SecEdgar::AnnualReport.new \n")
fh.write("          ten_k2.log = Logger.new('sec_edgar.log')\n")
fh.write("          ten_k2.log.level = Logger::DEBUG\n")
fh.write("          cur_file = files.shift\n")
fh.write("          ten_k2.parse(cur_file)\n")
fh.write("          summary2 = ten_k2.get_summary\n")
fh.write("        \n")
fh.write("          summary.merge(summary2) if !summary2.nil?\n")
fh.write("        end\n")
fh.write("      end\n")
fh.write("\n")
fh.write("    end\n")
fh.write("  return true\n")
fh.write("  end\n")
fh.write("end\n")
fh.write("\n")
fh.write("describe SecEdgar::Edgar do\n")
fh.write("\n")
fh.write("  describe 'parsing' do\n")

fh.write("    it 'can parse #{ticker}' do\n")
fh.write("      test_fn('#{ticker}').should == true\n")
fh.write("    end\n")

fh.write("  end\n")
fh.write("   \n")
fh.write("end\n")

exit 0
