#! /usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'rss/maker'
require 'rdiscount'

if ARGV[0]
  FILENAME = ARGV[0]
else
  raise "Please pass in the filename like this: ./generate_feed.rb /home/user/rss.xml"
end

def get_feed
  file = File.open(FILENAME, 'r')
  RSS::Parser.parse(file, false)
end

# check if version is already present in the feed
def is_new(version)
  url = get_url version
  get_feed.items.each do |i|
    if i.link == url
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

  feed = get_feed

  item = RSS::Rss::Channel::Item.new
  item.title = "Git v#{version} Release Notes"
  item.link = get_url version
  item.date = Time.now()
  item.description = html_notes
  item.guid = RSS::Rss::Channel::Item::Guid.new

  items = feed.channel.items
  items.slice!(15..items.size)
  feed.channel.items.unshift item
  write_to_file feed
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

puts "Script started at #{Time.now}"

# actual workflow
if !File.exist?(FILENAME)
  puts "*** Feed doesn't exist yet, initialising ***"
  init_feed
else
  doc = Hpricot(open("http://git-scm.com/"))
  ver = doc.at("span.version").inner_text.strip

  if is_new ver
    puts "*** New version #{ver} found, adding to feed ***"
    add_item ver
  else
    puts "*** Version #{ver} already in feed, exitting ***"
  end

end
