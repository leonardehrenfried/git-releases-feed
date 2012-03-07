#! /usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rss/maker'
require 'rdiscount'

doc = Hpricot(open("http://git-scm.com/"))
ver = doc.at("div#ver").inner_text
ver = ver[1..-1] #remove leading 'v'

url = "https://raw.github.com/gitster/git/master/Documentation/RelNotes/#{ver}.txt" 
release_notes = open(url){ |f| f.read }
markdown = RDiscount.new(release_notes)
html_notes = markdown.to_html

feed = RSS::Maker.make("2.0") do |m|
  m.channel.title = "Git Release Notes"
  m.channel.link = "http://git-com.com"
  m.channel.description = "Git Release notes."
  m.items.do_sort = true

  i = m.items.new_item
  i.title = "Git #{ver} release notes" 
  i.link = url
  i.description = html_notes
  i.date = Time.now
end

destination = "rss.xml"
File.open(destination, "w") do |f|
  f.write(feed)
end

