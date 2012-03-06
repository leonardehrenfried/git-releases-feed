#! /usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'

doc = Hpricot(open("http://git-scm.com/"))
ver = doc.at("div#ver").inner_text
ver = ver[1..-1] #remove leading 'v'

print ver
