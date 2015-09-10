# Someone already made a nice gem for parsing public profiles:
# https://github.com/yatish27/linkedin-scraper
# This class reopens that to add extra things I need
module Linkedin
  class Profile
    include ProxyManager
    include GetRelated
    
    def initialize(url, driver, curhops, proxylist, usedproxies, use_proxies_li)
      @linkedin_url = url
      @curhops = curhops
      @proxylist = proxylist
      @usedproxies = usedproxies
      
      # Add attributes to list
      ATTRIBUTES.push(
        "related_people",
        "profile_url",
        "timestamp",
        "degree",
        "pic_path")

      # Get page
      @driver = driver
      @page = Nokogiri::HTML(getPage(url, @driver, nil, 5, use_proxies_li).page_source)
      sleep(10)
    end


    def self.get_profile(url, driver, curhops, proxylist, usedproxies, use_proxies_li)
      Linkedin::Profile.new(url, driver, curhops, proxylist, usedproxies, use_proxies_li)
    rescue => e
      puts e
    end

    # Gets "people also viewed list" form profile sidebar
    def related_people
      @related_people ||= getList(@page)
    end

    # Similar to linkedin_url
    def profile_url
      @profile_url ||= @linkedin_url
    end

    # Get the time the profile was scraped
    def timestamp
      @timestamp ||= Time.now
    end

    # Get the number of hops out where profile appears
    def degree
      @degree ||= @curhops
    end

    # Download the profile picture
    def pic_path
      if picture
        # Get path
        dir = "public/uploads/pictures/"
        full_path = dir+picture.split("/").last.chomp.strip

        # Get file
        `wget -P #{dir} #{picture}` if !File.file?(full_path)
        return full_path
      end
    end
    
  end
end
