#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'
require 'date'
require 'csv'

require 'colorize'
require 'pry'
require 'csv'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  url.prepend @BASE unless url.start_with? 'http:'
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('ul.member-box li a[@class*="member-details"]/@href').map(&:text).each do |mplink|
    scrape_mp(mplink)
  end

  if next_arrow = noko.at_css('div.pagination-btm img[@src*="next.gif"]')
    scrape_list(next_arrow.parent.attr('href'))
  end
end

def scrape_mp(url)
  noko = noko_for(url)
  box = noko.css('.memberabouttext')
  data = { 
    id: File.basename(url),
    name: box.at_xpath('.//strong[contains(.,"Name")]//following::text()').text.strip,
    executive: box.at_xpath('.//strong[contains(.,"Designation")]//following::text()').text.strip,
    constituency: box.at_xpath('.//strong[contains(.,"Constituency")]//following::text()').text.strip,
    start_date: datefrom(box.at_xpath('.//strong[contains(.,"Election Date")]//following::text()').text.strip).to_s,
    party: box.at_xpath('.//strong[contains(.,"Party")]//following::text()').text.strip,
    email: box.at_css('div.pop-emailid').text.strip,
    img: box.at_css('div.left-img img/@src').text,
    source: url,
    term: 3,
  }
  data[:role] = '' if data[:role] == 'MP'
  puts data
  ScraperWiki.save_sqlite([:id, :term], data)
end


@BASE = 'http://www.nab.gov.bt'
@PAGE = @BASE + '/member/list_of_members'
scrape_list(@PAGE)

