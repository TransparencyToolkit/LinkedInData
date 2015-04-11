module GetRelated
  # Get the list of names of related people
  def getList(html)
    namelist = Array.new
       
    # Save each person's name and url
    html.css("div.insights-browse-map").each do |d|
      if d.css("h3").text == "People Also Viewed"
        d.css("li").each do |l|
          namelist.push({name: l.css("h4").text,
                         url: l.css("a")[0]['href']})
        end
      end
    end
      
    return namelist
  end

  
  # Get all profiles within numhops of original(s)
  def getRelatedProfiles
    @numhops.times do |hop_count|
      @output.select { |profile| profile[:degree] == hop_count }.each do |item|
        downloadRelated(item, hop_count) if item[:related_people]
      end
    end
  end

  # Scrapes the related profiles for one result item
  def downloadRelated(item, hop_count)
    item[:related_people].each do |related_person|
      # Check if it has been scraped already
      if @output.select { |person| related_person[:name] == person[:name] }.empty?
        scrape(related_person[:url], hop_count+1)
      end
    end
  end

  
  # Make list of profiles for score tracking
  def fullProfileList(data)
    profiles = Hash.new
    data.each do |d|
      profiles[d[:profile_url]] = 0
    end
    return profiles
  end

  # Adds points to a profile for showing up in related people
  def addPointsToProfile(profile_scores, data_item, person)
    if profile_scores[person[:url]]
      # Calculate degree- (2/d*2) except when degree is 0
      degree_divide = data_item[:degree] == 0 ? 1 : data_item[:degree]*2
      profile_scores[person[:url]] += (2.0/degree_divide)
    end
    return profile_scores
  end

  # Add a score to each profile based on the # of times it appears in "people also viewed"
  def relScore(data)
    profile_scores = fullProfileList(data)
    
    # Get degree and calculate score for each profile
    data.each do |data_item|
      if data_item[:related_people]
        data_item[:related_people].each do |person|
          profile_scores = addPointsToProfile(profile_scores, data_item, person)
        end
      end
    end

    # Merge scores back into dataset
    data.each do |m|
      m.merge!(score: profile_scores[m[:profile_url]])
    end

    return data
  end
end

