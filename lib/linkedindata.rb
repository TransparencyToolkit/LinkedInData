require 'mechanize'
require 'linkedin-scraper'
require 'json'
require 'nokogiri'
require 'open-uri'

class LinkedinData
  def initialize(input, todegree)
    @input = input
    @output = Array.new
    @startindex = 10
    @degree = 0
    if todegree == nil
      @to_degree = 0
    else
      @to_degree = todegree
    end
  end

  # Searches for links on Google
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
          sleep(rand(30..90))
          @startindex += 10
          agent = Mechanize.new
          examine(agent.get("http://google.com" + link.href))
        end
      end
    end
  end

  # Scrapes profile and makes JSON
  def scrape(url)
    flag = 0
    @output.each do |o|
      if o[:profile_url] == url
        flag = 1
        if @degree < o[:degree]
          o[:degree] = @degree
        end
      end
    end

    profile = Linkedin::Profile.get_profile(url)
    
    if profile
      profile.current_companies.each do |c|
        c.merge!(:skills => profile.skills, :certifications => profile.certifications, :languages => profile.languages, :name => profile.first_name + " " + profile.last_name, :location => profile.location, :area => profile.country, :industry => profile.industry, :picture => profile.picture, :organizations => profile.organizations, :groups => profile.groups, :education => profile.education, :websites => profile.websites, :profile_url => url, :degree => @degree, :current => "Yes")

        if profile.picture
          path = profile.picture.split("/")
          if !File.file?("public/uploads/pictures/" + path[path.length-1].chomp.strip)
            `wget -P public/uploads/pictures #{profile.picture}`
          end
          c.merge!(:pic_path => "public/uploads/pictures/" + path[path.length-1].chomp.strip)
        end

        @output.push(c)
      end
      
      profile.past_companies.each do |c|
        c.merge!(:skills => profile.skills, :certifications => profile.certifications, :languages => profile.languages, :name => profile.first_name + " " + profile.last_name, :location => profile.location, :area => profile.country, :industry => profile.industry, :picture => profile.picture, :organizations => profile.organizations, :groups => profile.groups, :education => profile.education, :websites => profile.websites, :profile_url => url, :degree => @degree, :current => "No")
        @output.push(c)

        if profile.picture
          path = profile.picture.split("/")
          if !File.file?("public/uploads/pictures/" + path[path.length-1].chomp.strip)
            `wget -P public/uploads/pictures #{profile.picture}`
          end
          c.merge!(:pic_path => "public/uploads/pictures/" + path[path.length-1].chomp.strip)
        end
      end

      # Clean up directories
      pics = Dir["public/uploads/*.jpg.*"]
      pics.each do |p|
        File.delete(p)
      end
      getRelated(url)
    end
  end

  # Gets related profiles listed on side of the page
  def getRelated(url) 
    if @degree < @to_degree
      html = Nokogiri::HTML(open(url))
      html.css("li.with-photo").each do |l|
        plink = l.css("a")[0]['href'].split("?")

        # Check to be sure not already saved
        flag = 0
        @output.each do |o|
          if o[:profile_url] == plink[0]
            flag = 1
          end
        end

        if flag == 0
          @degree += 1
          scrape(plink[0])
          @degree -= 1
        end
      end
    end
  end

  # Gets all data and returns in JSON
  def getData
    search
    return JSON.pretty_generate(@output)
  end
end
