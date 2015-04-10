require 'mechanize'
require 'linkedin-scraper'
require 'generalscraper'
require 'json'
require 'nokogiri'
require 'open-uri'
load 'parseprofile.rb'
require 'pry'
require 'urlarchiver'
require 'set'

class LinkedinData
  def initialize(searchterms, todegree, proxy_list)
    @searchterms = searchterms
    @proxy_list = proxy_list
    @output = Array.new
    @startindex = 10
    @numhops = todegree
  end

  # TODO:
  # Make it possible to just get one profile plus degrees out
  # Change parser
  # Refactor
  # Readme and gems

  # Searches for profiles on Google
  def search
    g = GeneralScraper.new("site:linkedin.com/pub", @searchterms, @proxy_list)
    JSON.parse(g.getURLs).each do |profile|
      scrape(profile, @numhops)
    end
  end

  # Scrapes profile
  def scrape(url, curhops)
    # Download profile and rescue on error
    begin
      url.gsub!("https", "http")
      profile = Linkedin::Profile.get_profile(url)
    rescue
    end
    
    # Parse profile if returned
    if profile
      p = ParseProfile.new(profile, url, curhops)
      @output.concat(p.parse)
    end
  end

  # Make sure all keys that occur occur in each item (even if nil)
  def showAllKeys(data)
    # Get all keys
    fields = Set.new
    data.map { |o| fields.merge(o.keys) }

    # Make sure all items have all keys
    datarr = Array.new
    data.each do |d|
      temphash = Hash.new
      fields.each do |f|
        if !d[f]
          temphash[f] = nil
        else
          temphash[f] = d[f]
        end
      end
      datarr.push(temphash)
    end

    return datarr
  end

  # Add a score to each profile based on the # of times it appears in "people also viewed"
  def relScore(data)

    # Make list of profiles
    profiles = Hash.new
    data.each do |d|
      profiles[d["profile_url"]] = 0
    end

    # Get degree for each profile
    data.each do |i|
      if i["related_people"]
        i["related_people"].each do |p|
          if profiles[p["url"]]
            # Calculate degree- (2/d*2) except when degree is 0
            degree_divide = i["degree"] == 0 ? 1 : i["degree"]*2
            profiles[p["url"]] += (2.0/degree_divide)
          end
        end
      end
    end

    # Merge scores back into dataset
    data.each do |m|
      m.merge!(:score => profiles[m["profile_url"]])
    end

    return data
  end

  # Gets all data and returns in JSON
  def getData
    search

    # Get related profiles
    @numhops.times do
      @output.each do |o|
        if o[:degree] < @numhops

          if o[:related_people]
            o[:related_people].each do |i|
              if @output.select { |obj| obj[:name] == i[:name]}.empty?
                scrape(i[:url], o[:degree]+1)
              end
            end
          end

        end
      end
    end

    formatted_json = JSON.pretty_generate(relScore(showAllKeys(@output)))
    return formatted_json
  end
end

l = LinkedinData.new("xkeyscore SIGINT", 0, "../../newproxylist")
puts l.getData
