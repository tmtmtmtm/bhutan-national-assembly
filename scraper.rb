#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'date'
require 'pry'
require 'scraped'
require 'scraperwiki'

require_rel 'lib'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class MembersPage < Scraped::HTML
  field :member_urls do
    noko.css('ul.member-box li a[@class*="member-details"]/@href').map(&:text)
  end

  field :next_page do
    if next_arrow = noko.at_css('div.pagination-btm img[@src*="next.gif"]')
      next_arrow.parent.attr('href')
    end
  end
end

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

def scrape_list(url)
  page = scrape(url => MembersPage)
  page.member_urls.each do |mplink|
    scrape_mp(mplink)
  end

  scrape_list(page.next_page) if page.next_page
end

def scrape_mp(url)
  data = scrape(url => MemberPage).to_h.merge(term: 2)
  # puts data
  ScraperWiki.save_sqlite(%i[id term], data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
start = 'http://www.nab.gov.bt/member/list_of_members'
scrape_list(start)
