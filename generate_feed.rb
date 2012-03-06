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

puts html_notes

version = "2.0"
destination = "feed.xml"

feed = RSS::Maker.make(version) do |m|
  m.channel.title = "Git Release Notes"
  m.channel.link = "http://lenni.info"
  m.channel.description = "Git Release notes."
  m.items.do_sort = true

  i = m.items.new_item
  i.title = "Git #{ver} release notes" 
  i.link = url
  i.time = Time.now
end

File.open(destination, "w") do |f|
  f.write(feed)
end

