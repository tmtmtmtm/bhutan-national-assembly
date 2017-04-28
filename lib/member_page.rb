# frozen_string_literal: true

require 'scraped'

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
