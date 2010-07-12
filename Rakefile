# -*- ruby -*-

require 'rake'	
require 'spec/rake/spectask'
require 'pp'

require "rubygems"

task :default => [:spec] do end

Spec::Rake::SpecTask.new(:spec) do |t|
#  ENV['RUBYOPT']='-rrubygems -rrticulate-env'
  t.spec_files = Dir.glob('spec/**/*_spec.rb').find_all {|x| ! /_slow_/.match(x) }
  t.spec_opts << '--format specdoc'
end

task :debug, :options do |t,args|
  ENV['RUBYLIB']='lib'
#  ENV['RUBYOPT']='-rrubygems -rrticulate-env'
  Kernel.exec "irb -r formby #{args.options}"
end

task :rdoc do
  sh "rdoc -T frameless -S README.rdoc lib/*.rb"
end

rule /generated\/.*/ => [proc {|f| v="etc/#{File.basename(f)}.erb"},'config.yml'] do |t|
  template=ERB.new(File.read(t.source))
  File.open(t.name,"w") do |out|
    out.puts(template.result)
  end
end

