require 'mechanize'
require 'linkedin-scraper'
require 'json'
require 'nokogiri'
require 'open-uri'
load 'parseprofile.rb'
require 'pry'

class LinkedinData
  def initialize(input, todegree)
    @input = input
    @output = Array.new
    @startindex = 10
  end

  # Searches for profiles on Google
  def search
    agent = Mechanize.new
    agent.user_agent_alias = 'Linux Firefox'
    gform = agent.get("http://google.com").form("f")
    gform.q = "site:linkedin.com/pub " + @input
    page = agent.submit(gform, gform.buttons.first)
    examine(page)
  end
 
  # Examines a search page
  def examine(page)
    # Separate getting profile links and going to next page
      # Method for getting links to all result pages
      # Different method for getting all profile links on page and scraping (split to new thread for this)
         # Has own output set, merge into full one at end (make sure threadsafe)
    linklist = getGoogleResults(page, Hash.new)

    # Get profiles for all results
    linklist.each do |resulturl, body|
      Thread.new{getProfileLinks(body)}
    end
  end

  # Get html of Google results pages
  def getGoogleResults(html, linklist)
    html.links.each do |link|
     if (link.href.include? "&sa=N") && (link.href.include? "&start=")
        url1 = link.href.split("&start=")                                                                                              
        url2 = url1[1].split("&sa=N")

        # If link matches current index, add to linklist
        if url2[0].to_i == @startindex                                                                                                 
          sleep(rand(5..10))
          agent = Mechanize.new
          page = agent.get("http://google.com"+link.href)
          linklist["http://google.com"+link.href] = page
          @startindex += 10
          getGoogleResults(page, linklist)
        end
     end
    end
    return linklist
  end

  # Get and scrape profiles from page
  def getProfileLinks(body)
    threadout = Array.new

    body.links.each do |link|
      # Check if it links to a LinkedIn profile
      if (link.href.include? "linkedin.com") && (!link.href.include? "webcache") && (!link.href.include? "site:linkedin.com/pub+")
        saveurl = link.href.split("?q=")
        
        # If there is a link, scrape it
        if saveurl[1]
          url = saveurl[1].split("&")
          begin
            threadout.concat(scrape(url[0]))
          rescue
          end
        end
      end
    end
  end

  # Scrapes profile
  def scrape(url)
    # Download profile and rescue on error
    begin
      url.gsub!("https", "http")
      profile = Linkedin::Profile.get_profile(url)
    rescue
    end
    
    # Parse profile if returned
    if profile
      p = ParseProfile.new(profile, url)
      return p.parse
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    return JSON.pretty_generate(@output)
  end
end


