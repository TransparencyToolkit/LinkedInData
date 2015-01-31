require 'json'
load 'getrelated.rb'

class ParseProfile
  def initialize(profile, url, curhops)
    @profile = profile
    @url = url
    @output = Array.new
    @related_people
    @curhops = curhops
  end

  # Parse profile
  def parse
    begin
      g = GetRelated.new(@url)
      @related_people = g.getList
    rescue
    end

    # Parse profiles for current companies
    @profile.current_companies.each do |c|
      @output.push(parseCompany(c, "Yes"))
    end

    # Parse past position/company info
    @profile.past_companies.each do |c|
      @output.push(parseCompany(c, "No"))
    end

    # Clean up directories
    pics = Dir["public/uploads/*.jpg.*"]
    pics.each do |p|
      File.delete(p)
    end
    
    return @output
  end

  # Merge person data with role data   
  def parseCompany(c, status)
    c.merge!(
             :skills => @profile.skills,
             :certifications => @profile.certifications,
             :languages => @profile.languages,
             :name => @profile.first_name + " " + @profile.last_name,
             :location => @profile.location,
             :area => @profile.country,
             :industry => @profile.industry,
             :picture => @profile.picture,
             :organizations => @profile.organizations,
             :groups => @profile.groups,
             :education => @profile.education,
             :websites => @profile.websites,
             :profile_url => @url,
             :current => status,
             :timestamp => Time.now,
             :related_people => @related_people,
             :degree => @curhops)
    c.merge!(:pic_path => getPic)
    return c
  end

  # Download pictures   
  def getPic
    if @profile.picture
      path = @profile.picture.split("/")
      if !File.file?("public/uploads/pictures/" + path[path.length-1].chomp.strip)
        begin
          `wget -P public/uploads/pictures #{@profile.picture}`
        rescue
        end
      end

      return "public/uploads/pictures/" + path[path.length-1].chomp.strip
    end
  end
end
