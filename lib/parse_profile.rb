module ParseProfile
  # Parse profile into items by company
  def parseResume(profile)
    output = Array.new
    
    # Parse profiles for current companies
    profile.current_companies.each do |c|
      output.push(addPersonFields(c, "Yes", profile))
    end

    # Parse past position/company info
    profile.past_companies.each do |c|
      output.push(addPersonFields(c, "No", profile))
    end

    return output
  end

  # Deletes duplicate pictures
  def deleteDuplicatePics
    pics = Dir["public/uploads/pictures/*.jpg.*"]
    pics.each do |p|
      File.delete(p)
    end
  end

  # Merge person data with role data   
  def addPersonFields(c, status, profile)
    c.merge!(
             skills: profile.skills,
             certifications: profile.certifications,
             languages: profile.languages,
             name: profile.name,
             location: profile.location,
             area: profile.country,
             industry: profile.industry,
             picture: profile.picture,
             organizations: profile.organizations,
             groups: profile.groups,
             education: profile.education,
             websites: profile.websites,
             profile_url: profile.profile_url,
             summary: profile.summary,
             current: status,
             timestamp: profile.timestamp,
             related_people: profile.related_people,
             degree: profile.degree,
             pic_path: profile.pic_path)
    return c
  end
end
