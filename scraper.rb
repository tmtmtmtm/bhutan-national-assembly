#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'date'
require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

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
  (party_name, party_id) = box.at_xpath('.//strong[contains(.,"Party")]//following::text()').text.tidy.match(/(.*)\s+\((.*)\)/).captures
  data = {
    id:           File.basename(url),
    name:         box.at_xpath('.//strong[contains(.,"Name")]//following::text()').text.tidy,
    executive:    box.at_xpath('.//strong[contains(.,"Designation")]//following::text()').text.tidy,
    constituency: box.at_xpath('.//strong[contains(.,"Constituency")]//following::text()').text.tidy,
    start_date:   datefrom(box.at_xpath('.//strong[contains(.,"Election Date")]//following::text()').text.tidy).to_s,
    party_name:   party_name,
    party_id:     party_id,
    email:        box.at_css('div.pop-emailid').text.tidy,
    img:          box.at_css('div.left-img img/@src').text,
    source:       url,
    term:         2,
  }
  data[:executive] = '' if data[:executive] == 'MP'
  # puts data
  ScraperWiki.save_sqlite(%i(id term), data)
end

@BASE = 'http://www.nab.gov.bt'
@PAGE = @BASE + '/member/list_of_members'
scrape_list(@PAGE)
