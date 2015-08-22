require 'linkedin-scraper'
require 'generalscraper'
require 'json'
require 'nokogiri'
require 'set'
require 'pry'

load 'parse_profile.rb'
load 'get_related.rb'
load 'linkedin.rb'

class LinkedinData
  include GetRelated
  include ParseProfile
  include Linkedin
  
  def initialize(todegree, proxylist, use_proxy, use_proxy_li)
    @proxylist = IO.readlines(proxylist)
    @proxy_list_path = proxylist
    @usedproxies = Hash.new
    @output = Array.new
    @startindex = 10
    @numhops = todegree
    @use_proxy = use_proxy
    @use_proxy_li = use_proxy_li
  end

  # Searches for profiles on Google
  def search(search_terms)
    g = GeneralScraper.new("site:linkedin.com/pub", search_terms, @proxy_list_path, @use_proxy)
    JSON.parse(g.getURLs).each do |profile|
      scrape(profile, 0)
    end
  end

  # Scrapes and parses individual profile
  def scrape(url, curhops)
    # Download profile and rescue on error
    begin
      url.gsub!("https", "http")
      profile = Linkedin::Profile.get_profile(url, curhops, @proxylist, @usedproxies, @use_proxy_li)

      # Parse profile if returned and add to output
      @output.concat(parseResume(profile)) if profile
    rescue
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

  # Gets related profiles then adds relevance scores and any missing keys
  def prepareResults
    getRelatedProfiles
    deleteDuplicatePics
    return JSON.pretty_generate(relScore(showAllKeys(@output)))
  end

  # Gets one profile and the related profiles
  def getSingleProfile(url)
    scrape(url, 0)
    return prepareResults
  end
  
  # Gets all profiles in search results and returns in JSON
  def getByKeywords(search_term)
    search(search_term)
    return prepareResults
  end
end
