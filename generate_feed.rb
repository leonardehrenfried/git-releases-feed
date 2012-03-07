#! /usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rss/maker'
require 'rdiscount'

FILENAME = "rss.xml"

def get_feed
  file = File.open(FILENAME, 'r') 
  RSS::Parser.parse(file, false)
end

# check if version is already present in the feed
def is_new(version)
  url = get_url version
  get_feed.items.each do |i|
    is_new = i.link == url
    if is_new:
      return false
    end
  end
  return true
end

def get_url(version)
  "https://raw.github.com/gitster/git/master/Documentation/RelNotes/#{version}.txt"
end

def add_item(version)
  release_notes = open(get_url version){ |f| f.read }
  markdown = RDiscount.new(release_notes)
  html_notes = markdown.to_html

  old_feed = get_feed
  
  # unfortunately I don't seem to be able to add to a parsed feed
  # so i need to copy new stuff to a new feed
  content = RSS::Maker.make("2.0") do |m|
    m.channel.title = old_feed.channel.title 
    m.channel.link = old_feed.channel.link 
    m.channel.description = old_feed.channel.link
    m.items.do_sort = true # sort items by date

    old_feed.channel.items.each do |old_item|
      i = m.items.new_item
      i.title = old_item.title 
      i.link = old_item.link 
      i.date = old_item.date
      i.description = old_item.description
    end
    
    i = m.items.new_item
    i.title = "Git v#{version} Release Notes" 
    i.link = get_url version 
    i.date = Time.now()
    i.description = html_notes
  end

  write_to_file content 
end

def init_feed()
  feed = RSS::Maker.make("2.0") do |m|
    m.channel.title = "Git Release Notes"
    m.channel.link = "http://git-scm.com"
    m.channel.description = "Git Release notes."
    m.items.do_sort = true
  end
  write_to_file feed

  # prepopulate
  ["1.7.8", "1.7.8.1", "1.7.8.2", "1.7.8.3", "1.7.8.4", "1.7.8.5", "1.7.9", 
    "1.7.9.1", "1.7.9.2", "1.7.9.3"].each do |ver|
    puts "*** Adding version #{ver} to initial feed"
    add_item ver      
    end
end

def write_to_file(feed)
  File.open(FILENAME, 'w') {|f| f.write(feed) }
end

# actual workflow
if !File.exist?(FILENAME):
  puts "*** Feed doesn't exist yet, initialising ***"
  init_feed
else
  doc = Hpricot(open("http://git-scm.com/"))
  ver = doc.at("div#ver").inner_text
  ver = ver[1..-1] #remove leading 'v'

  if is_new ver:
    puts "*** New version #{ver} found, adding to feed ***"
    add_item ver
  else
    puts "*** Version #{ver} already in feed, exitting ***"
  end

end
