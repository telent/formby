 
Gem::Specification.new do |s|
  s.name        = "formby"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Daniel Barlow"]
  s.email       = ["dan@telent.net"]
  s.homepage    = "http://github.com/telent/formby"
  s.summary     = "Erector widgets for managing HTML form elements"
  s.description = "Formby extends the Erector library with a bunch of widgets that make HTML form creation and processing much les tedious"
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_dependency "erector"
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(README.rdoc Rakefile)
#  s.executables  = ['bundle']
  s.require_path = 'lib'
end