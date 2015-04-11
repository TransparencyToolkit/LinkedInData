This gem finds all LinkedIn profiles including terms you specify and scrapes them.

To use-
1. Download the gem 'linkedindata' and add it to your gemfile
2. Make a new LinkedinData object: l = LinkedinData.new(# of hops to go out, path to proxy list)
3. Specify which profiles to get and the search terms or URL-
..* Single Profile: l.getSingleProfile(url)
..* List of Profiles Matching Search Terms: l.getByKeywords("search terms")

[![Code Climate](https://codeclimate.com/github/TransparencyToolkit/LinkedInData/badges/gpa.svg)](https://codeclimate.com/github/TransparencyToolkit/LinkedInData)
