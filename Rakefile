require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.warning = true
end


task :compile => [
  'lib/rack/mount/strexp/parser.rb',
  'lib/rack/mount/strexp/tokenizer.rb'
]

file 'lib/rack/mount/strexp/parser.rb' => 'lib/rack/mount/strexp/parser.y' do |t|
  sh "racc -l -o #{t.name} #{t.prerequisites.first}"
  sh "sed -i '' -e 's/    end   # module Mount/  end   # module Mount/' #{t.name}"
  sh "sed -i '' -e 's/  end   # module Rack/end   # module Rack/' #{t.name}"
end

file 'lib/rack/mount/strexp/tokenizer.rb' => 'lib/rack/mount/strexp/tokenizer.rex' do |t|
  sh "rex -o #{t.name} #{t.prerequisites.first}"
end

namespace :vendor do
  task :update => [:update_reginald, :update_multimap]

  task :update_reginald do
    system 'git clone git://github.com/josh/reginald.git'
    FileUtils.rm_rf('lib/rack/mount/vendor/reginald')
    FileUtils.cp_r('reginald/lib', 'lib/rack/mount/vendor/reginald')
    FileUtils.rm_rf('reginald')

    FileUtils.rm_rf('lib/rack/mount/vendor/reginald/reginald/parser.y')
    FileUtils.rm_rf('lib/rack/mount/vendor/reginald/reginald/tokenizer.rex')
  end

  task :update_multimap do
    system 'git clone git://github.com/josh/multimap.git'
    FileUtils.rm_rf('lib/rack/mount/vendor/multimap')
    FileUtils.cp_r('multimap/lib', 'lib/rack/mount/vendor/multimap')
    FileUtils.rm_rf('multimap')
  end
end
