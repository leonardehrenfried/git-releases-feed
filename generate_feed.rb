#! /usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rss/maker'
require 'rdiscount'


FILENAME = "rss.xml"

def is_new(version)
  puts value 
end

def get_url(version)
  "https://raw.github.com/gitster/git/master/Documentation/RelNotes/#{version}.txt"
end

def add_new(version)
  release_notes = open(get_url version){ |f| f.read }
  markdown = RDiscount.new(release_notes)
  html_notes = markdown.to_html
  
  feed = RSS::Maker.make("2.0") do |m|
    m.channel.title = "Git Release Notes"
    m.channel.link = "http://git-com.com"
    m.channel.description = "Git Release notes."
    m.items.do_sort = true

    i = m.items.new_item
    i.title = "Git #{version} Release Notes" 
    i.link = get_url version
    i.description = html_notes
    i.date = Time.now
  end

  write_to_file feed
end

def write_to_file(feed)
  File.open(FILENAME, "w") do |f|
    f.write(feed)
  end
end

doc = Hpricot(open("http://git-scm.com/"))
ver = doc.at("div#ver").inner_text
ver = ver[1..-1] #remove leading 'v'
add_new ver


