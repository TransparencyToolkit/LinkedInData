require 'json'
require 'nokogiri'
require 'open-uri'

module GetRelated
  include ProxyManager
  # TODO:
  # Refactor and test
  
  # Get the list of names of related people
  def getList(url)
    html = Nokogiri::HTML(getPage(url).body)
    
    if html
       namelist = Array.new
       
      # Go through each person
      html.css("div.insights-browse-map").each do |d|
        if d.css("h3").text == "People Also Viewed"
          d.css("li").each do |l|
            temphash = Hash.new
            temphash[:name] = l.css("h4").text
            temphash[:url] = l.css("a")[0]['href']
            namelist.push(temphash)
          end
        end
      end
      
      return namelist
    end
  end

  # Get profiles from related people list on side
  def getRelatedProfiles
    @numhops.times do |hop_count|
      @output.select { |profile| profile[:degree] == hop_count }.each do |item|
        if item[:related_people]
          item[:related_people].each do |related_person|
            scrape(related_person[:url], hop_count+1) if @output.select { |person| related_person[:name] == person[:name] }.empty?
          end
        end
      end
    end
  end

  # Add a score to each profile based on the # of times it appears in "people also viewed"
  def relScore(data)
    # Make list of profiles for tracking scores
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
end

