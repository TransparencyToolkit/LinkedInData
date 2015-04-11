require 'linkedin-scraper'
require 'generalscraper'
require 'json'
require 'nokogiri'

load 'parse_profile.rb'
load 'get_related.rb'
load 'linkedin.rb'

require 'pry'
require 'set'

class LinkedinData
  include GetRelated
  include ParseProfile
  
  def initialize(searchterms, todegree, proxylist)
    @searchterms = searchterms
    @proxylist = IO.readlines(proxylist)
    @proxy_list_path = proxylist
    @usedproxies = Hash.new
    @output = Array.new
    @startindex = 10
    @numhops = todegree
  end

  # TODO:
  # Clean up get related (and use generalscraper)
  # Clean up/change parser (and use generalscraper and add related)
  # Make it possible to just get one profile plus degrees out
  # Maybe change how proxy_manager handles vars with proxy details
  # Look at showAllKeys again
  # Readme and gems, clean up includes

  # Searches for profiles on Google
  def search
    g = GeneralScraper.new("site:linkedin.com/pub", @searchterms, @proxy_list_path)
    JSON.parse(g.getURLs).each do |profile|
      scrape(profile, 0)
    end
  end

  # Scrapes and parses individual profile
  def scrape(url, curhops)
    # Download profile and rescue on error
    begin
      url.gsub!("https", "http")
      profile = Linkedin::Profile.get_profile(url, curhops, @proxylist, @usedproxies)
    rescue
    end
    
    # Parse profile if returned and add to output
    @output.concat(parseResume(profile)) if profile    
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

  # Gets all data and returns in JSON
  def getData
    search
    getRelatedProfiles

    formatted_json = JSON.pretty_generate(relScore(showAllKeys(@output)))
    return formatted_json
  end
end

l = LinkedinData.new("xkeyscore SIGINT Tom Lothe Frankfurt", 1, "../../newproxylist")
puts l.getData
