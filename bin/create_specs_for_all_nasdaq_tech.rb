#!/usr/bin/env ruby

if ARGV.length < 1
  puts "Usage: ./bin/create_specs_for_all_nasdaq_tech.rb <number of companies to test against>"
  exit 0
end
num_tests = Integer(ARGV[0])



tech_tickers = ["VNET", "DDD", "JOBS", "AAN", "ACCL", "ACIW", "APKT", "ACTS", "ATVI", "ATU", "BIRT", "ACXM", "ADEP", "ADBE", "AATI", "AMD", "API", "ASX", "ATE", "ADVS", "AER", "ACY", "ARX", "AL", "AYR", "AMCN", "AIXG", "ALAN", "AFOP", "ALLT", "MDRX", "AOSL", "ALTR", "DOX", "AMSWA", "AMKR", "ASYS", "ANAD", "ADI", "ANLY", "ANEN", "ACOM", "ANSS", "AOL", "AAPL", "AMAT", "AMCC", "ARBA", "ARMH", "ARRS", "ARUN", "ASTI", "ASTIZ", "ASIA", "ASMI", "ASML", "AZPN", "ATEA", "ALOT", "ASUR", "ATML", "AUO", "AUTH", "ADAT", "ABTL", "ADSK", "ADP", "AMAP", "AVGO", "AVNW", "AWRE", "ACLS", "AXTI", "BOSC", "BIDU", "BYI", "BNX", "BBSI", "BCDS", "BHE", "BBND", "BITA", "BITS", "BBOX", "BLKB", "BBBB", "BDR", "BCSI", "BPHX", "BMC", "EPAY", "BLIN", "BRCM", "BSFT", "BVSN", "BRCD", "BRKS", "BTUI", "CA", "CCMP", "CACI", "CDNS", "CAP", "CAMP", "CALD", "CIS", "CSIQ", "CAVM", "CHINA", "CDCS", "CDI", "CLS", "CRNT", "CERN", "CEVA", "CYOU", "CHRM", "CHKP", "CVR", "STV", "CNIT", "CMM", "CSUN", "CTDC", "CTFO", "CCIH", "CNET", "IMOS", "CBR", "CIMT", "CRUS", "CSCO", "CTXS", "CLNT", "CLRO", "CKSW", "COBR", "CCOI", "CTSH", "CVLT", "CODI", "CPSI", "CSC", "CTGX", "CPWR", "CMTL", "CNQR", "CCUR", "CTCT", "CVG", "CNVO", "CLGX", "CSOD", "COVR", "CRAY", "CREE", "EXE", "CCRN", "CSGS", "CSPI", "CTP", "CW", "CVV", "CYDE", "CYMI", "CY", "DQ", "DTLK", "DRAM", "DWCH", "DSTI", "DDIC", "TRAK", "DELL", "PROJ", "DMD", "DMAN", "DLGC", "DGII", "DMRC", "DGLY", "DRIV", "DIOD", "DMC", "DLB", "HILL", "DOV", "DSPG", "DST", "DGW", "DRCO", "DVOX", "ELNK", "ESIC", "ETN", "EBIX", "ELON", "SATS", "EDGW", "EFUT", "ELRC", "ERTS", "EFII", "ELLI", "ELTK", "EMAN", "EMC", "EMKR", "ELMG", "ELX", "ENER", "ERII", "ENOC", "ENTR", "EPIQ", "PLUS", "EPOC", "ESLR", "EVOL", "EXAR", "EXH", "EXTR", "EZCH", "FFIV", "FDS", "FCS", "FALC", "FNSR", "FSLR", "FISV", "FLEX", "FMCN", "FORM", "FORTY", "FTNT", "FSL", "FFN", "FSII", "FNDT", "FIO", "GDI", "JOB", "GRB", "GIGM", "GILT", "GSB", "GCOM", "GLUU", "GOOG", "GHM", "GVP", "GSIT", "SOLR", "GTSI", "GUID", "HSOL", "HLIT", "HHS", "HAUP", "HSTM", "HSII", "HPQ", "HIMX", "HSFT", "HITT", "HHGP", "ICOG", "INVE", "IEC", "IGTE", "IGOI", "IHS", "ITW", "IMN", "IMMR", "MAIL", "INFA", "INSP", "INFY", "IM", "INOD", "ISSC", "IPHI", "NSP", "ISYS", "IDTI", "ISSI", "INTC", "IDN", "ININ", "INAP", "IBM", "IRF", "IIJI", "INPH", "IPG", "INTX", "ISIL", "INXN", "IVAC", "IL", "INTU", "IPAS", "IPGP", "ISS", "IXYS", "JCOM", "JASO", "JBL", "JCDA", "JKHY", "JDAS", "JDSU", "DATE", "JKS", "JBT", "JNPR", "KAI", "KELYA", "KELYB", "KNXA", "KTEC", "KTCC", "KFRC", "KONE", "KNM", "KONG", "KOPN", "KFY", "KLIC", "KVHI", "KYO", "ID", "LLL", "LRCX", "LAMR", "LTRX", "LSCC", "LWSN", "LDK", "LXK", "LPTH", "LECO", "LLTC", "LNKD", "LTON", "LIVE", "LPSN", "ERIC", "LOGI", "LOGM", "LFT", "LOOK", "LORL", "LSI", "LUFK", "MGIC", "LAVA", "MX", "COOL", "MMUS", "MKTAY", "MANH", "MNTX", "MAN", "MRVL", "MTSN", "MXIM", "MXL", "MGRC", "MDCA", "MDAS", "MDSO", "MEDW", "MEDH", "MLNX", "WFR", "MEMS", "MENT", "MRGE", "MERU", "MGT", "MCRL", "MCHP", "MU", "MCRS", "MSCC", "MSFT", "MSTR", "MNDO", "MSPD", "MIPS", "MIND", "MITL", "MPWR", "TYPE", "MWW", "MOG/A", "MOSY", "MMI", "MSI", "MFLX", "NATI", "NSM", "NAVR", "NCIT", "NPTN", "NSTC", "NTAP", "NLST", "NETL", "NQ", "NTCT", "NTWK", "N", "NEI", "NWK", "NICE", "NINE", "NED", "NOK", "NVLS", "DCM", "NUAN", "NVEC", "NVDA", "NXPI", "OIIM", "OCLR", "OCZ", "OMCL", "OMC", "OVTI", "ASGN", "ONNN", "OTIV", "ONSM", "OTEX", "OPWV", "OPNT", "OPXT", "OBAS", "ORCL", "ORB", "OSIS", "OVRL", "PFIN", "PSOF", "PMTC", "PCYG", "PKE", "PRKR", "PTI", "PCTI", "PDFS", "PRLS", "PEGA", "PNR", "PRFT", "PTIX", "PSEM", "PVSW", "ANTP", "PLAB", "PNS", "PXLW", "PLXS", "PLXT", "PMCS", "PNTR", "POWI", "PWAV", "PKT", "PRGS", "PRO", "QADA", "QADB", "QIHU", "QLIK", "QLGC", "QCOM", "QSII", "QBAK", "QTM", "QSFT", "QUIK", "RAX", "RDCM", "RADS", "RSYS", "RVSN", "RMBS", "RMTR", "RCMT", "RDA", "RLOC", "RLD", "RNWK", "RP", "RHT", "RWC", "RLRN", "SOL", "RENN", "RCII", "MKTG", "RTLX", "RFMD", "RFMI", "RNOW", "RIMG", "RVBD", "RHI", "RST", "RRR", "RBCN", "SONE", "SABA", "SAI", "CRM", "SNDK", "SANM", "SAP", "SPNS", "SAPE", "SATC", "SHS", "SCSC", "SGMS", "SQI", "SEAC", "STX", "SED", "SLTC", "SMI", "LEDS", "SMTC", "SQNS", "SFN", "SGOC", "SWIR", "SIFY", "SIGM", "SGMA", "SILC", "SGI", "SLAB", "SIMO", "SPIL", "SLP", "SINA", "MOBI", "SWKS", "SMOD", "SMT", "SMSI", "SMTX", "SCKT", "SOHU", "SWI", "SLH", "SOFO", "SONS", "SFUN", "FIRE", "CODE", "SPA", "SPIR", "SPRD", "SPSC", "SPW", "SRX", "SSNC", "SMSC", "SXI", "SRT", "STEC", "STM", "SSYS", "SGS", "STRM", "SFSF", "SPWRA", "SPWRB", "STP", "SMCI", "SCON", "SUPX", "SPRT", "SYKE", "SYMC", "SYNA", "SNCR", "SNX", "SNPS", "SYNT", "TSM", "TTWO", "TAL", "TLEO", "TMH", "TSTF", "TECD", "TCCO", "TGALD", "TKLC", "TSYS", "TTEC", "WRLS", "TNC", "TDC", "TSRA", "TXN", "TGH", "ACTV", "DSGX", "KEYW", "MIDD", "ULTI", "THQI", "TIBX", "TIER", "TIGR", "TISA", "TSEM", "TSEMG", "TACT", "TXCC", "TZOO", "TRID", "TSL", "TRT", "TQNT", "TBI", "TBOW", "TSRI", "TTMI", "TCX", "TWIN", "TYL", "UCTT", "UTEK", "UNFY", "UIS", "UMC", "UNTD", "URI", "IN", "VCLK", "VIT", "VSEA", "VDSI", "VECO", "VELT", "VRGY", "VRNT", "VRSN", "VRSK", "VSNT", "VSAT", "VIAS", "VIMC", "VRTU", "VISN", "VTSS", "VMW", "VOCS", "VLTR", "WAVX", "WSTG", "WWWW", "WGA", "WDC", "WYY", "WIT", "RNIN", "WZE", "WPPGY", "WSCI", "XATA", "XRX", "XLNX", "XRTX", "YHOO", "YNDX", "YGE", "YOKU", "YTEC", "ZBRA", "ZIXI", "ZOOG", "ZRAN", "ZSTN"].sort


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

tech_tickers[0..(num_tests-1)].each do |ticker|

  fh.write("    it 'can parse #{ticker}' do\n")
  fh.write("      test_fn('#{ticker}').should == true\n")
  fh.write("    end\n")
end

fh.write("  end\n")
fh.write("   \n")
fh.write("end\n")

