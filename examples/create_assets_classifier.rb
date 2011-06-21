#!/usr/bin/env ruby 

require 'rubygems'
require 'naive_bayes'
require 'lingua/stemmer'

a = NaiveBayes.new(:oa, :fa)
s = Lingua::Stemmer.new

fh = File.new("classifier_training/assets_training_scored.txt", "r")
fh.readlines.each do |cur_line|

  puts "cur_line: #{cur_line}"
  cur_tokens = cur_line.split(' ')
  cur_class = cur_tokens.shift
  cur_tokens.collect! { |x| s.stem(x) }

  case cur_class
  when "FA"
    a.train(:fa, *cur_tokens)
  when "OA"
    a.train(:oa, *cur_tokens)
  else
    raise "unknown class #{cur_class}"
  end

end
fh.close

["property, plant and equipment",
 "accounts receivable",
 "prepaid revenue",
 "cash and cash equivalents",
 "income tax payable"].each do |test_str|

  cur_tokens = test_str.split(' ').collect! { |x| s.stem(x) }
  ret = a.classify(*cur_tokens)
  puts "#{test_str} => [#{ret[0]}, #{ret[1]}]"

end

