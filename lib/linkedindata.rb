require 'mechanize'
require 'linkedin-scraper'
require 'json'

class LinkedinData
  def initialize(input)
   @input = input
   @output = Array.new
   @startindex = 10
  end

  # Searches for links on Google
  def search
    agent = Mechanize.new
    gform = agent.get("http://google.com").form("f")
    gform.q = "site:linkedin.com/pub " + @input
    page = agent.submit(gform, gform.buttons.first)
    examine(page)
  end
 
  # Examines a search page
  def examine(page)
    page.links.each do |link|
      if (link.href.include? "linkedin.com") && (!link.href.include? "webcache") && (!link.href.include? "site:linkedin.com/pub+")
        saveurl = link.href.split("?q=")
        
        if saveurl[1]
          url = saveurl[1].split("&")
          scrape(url[0])
        end
      end

      if (link.href.include? "&sa=N") && (link.href.include? "&start=")
        url1 = link.href.split("&start=")
        url2 = url1[1].split("&sa=N")

        if url2[0].to_i == @startindex
          sleep(20)
          @startindex += 10
          agent = Mechanize.new
          examine(agent.get("http://google.com" + link.href))
        end
      end
    end
  end

  # Scrapes profile and makes JSON
  def scrape(url)
    profile = Linkedin::Profile.get_profile(url)
    
    if profile
      profile.current_companies.each do |c|
        c.merge!(:name => profile.first_name + " " + profile.last_name)
        @output.push(c)
      end
      
      profile.past_companies.each do |c|
        c.merge!(:name => profile.first_name + " " + profile.last_name)
        @output.push(c)
      end
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    return JSON.pretty_generate(@output)
  end
end

l = LinkedinData.new("National Security Agency")
puts l.getData
