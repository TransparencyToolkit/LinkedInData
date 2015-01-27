require 'json'
require 'nokogiri'
require 'open-uri'

class GetRelated
  def initialize(url)
    @url = url
    @relatedlist = Array.new
  end
  
  # Get the list of names of related people
  def getList
    html = Nokogiri::HTML(open(@url))

    if html
       namelist = Array.new

      # Go through each person
      html.css("div.insights-browse-map").each do |d|
        d.css("li").each do |l|
          namelist.push(l.css("h4").text)
        end
      end

      return namelist
    end
  end
end

# This is just an outline for the next version of getrelated

# Add degree back as field (0 by default)
# Loop through all profiles
    # Load n times (need to determine optimal num)
       # Save list of related people (for profile- make list and append if seen listed as related or in related list)
       # Save overall list of related people (with URLs and min degree)
          # Track min degrees out

# Go through overall list of related people
     # Parse profile
     # Make sure degree is correct when saved
     # Maybe save in JSONs by degree


# Info:
  # Profiles of related people
  # Degrees for all profiles
  # Related people list on each profile (complete)

# Deduplicate
