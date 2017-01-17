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

class MemberPage < Scraped::HTML
  field :id do
    File.basename(url)
  end

  field :name do
    raw_name.sub('Lyonpo', '').tidy
  end

  field :honorific_prefix do
    'Lyonopo' if raw_name.include? 'Lyonpo'
  end

  field :executive do
    text = box.at_xpath('.//strong[contains(.,"Designation")]//following::text()').text.tidy
    return '' if text == 'MP'
    text
  end

  field :constituency do
    box.at_xpath('.//strong[contains(.,"Constituency")]//following::text()').text.tidy
  end

  field :start_date do
    datefrom(box.at_xpath('.//strong[contains(.,"Election Date")]//following::text()').text.tidy).to_s
  end

  field :party_name do
    party_data.first
  end

  field :party_id do
    party_data.last
  end

  field :email do
    box.at_css('div.pop-emailid').text.tidy
  end

  field :img do
    box.at_css('div.left-img img/@src').text
  end

  field :source do
    url
  end

  private

  def raw_name
    box.at_xpath('.//strong[contains(.,"Name")]//following::text()').text.tidy
  end

  def party_data
    box.at_xpath('.//strong[contains(.,"Party")]//following::text()').text.tidy.match(/(.*)\s+\((.*)\)/).captures
  end

  def box
    noko.css('.memberabouttext')
  end

  def datefrom(date)
    Date.parse(date)
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
  ScraperWiki.save_sqlite(%i(id term), data)
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
start = 'http://www.nab.gov.bt/member/list_of_members'
scrape_list(start)
