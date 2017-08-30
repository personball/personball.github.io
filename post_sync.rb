#!/usr/local/opt/ruby@2.3/bin/ruby
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'metaweblog'
require 'yaml'
require 'cnblogs_post'

config=YAML.load_file('post_sync.yml')

blogclient=MetaWeblog::Client.new(
  config['target'],
  '1',
  config['username'],
  config['password'],
  nil
)

filename=ARGV[0]
file=File.new(filename,'r')
content=''
header=''
line_ignore=false
while (line=file.gets)
  if line=="---\n"
    line_ignore=!line_ignore
  end
  header+=line unless(!line_ignore)
  line.gsub!(/"\/assets/,'"'+config['source']+'/assets')
  line.gsub!(/]\(\//,']('+config['source']+'/')
  content+=line unless (line_ignore||line=~/^{% include/)
end
headerYml=YAML.load(header)
puts headerYml.inspect
blog=MetaWeblog::CnblogsPost.new({
  :title=>"[#{filename[filename.index('/')+1,10]}]#{headerYml['title']}",
  :description=>content,
  :categories=>['[Markdown]'],
  :dateCreated=>Time.parse("#{filename[filename.index('/')+1,10]}")
})

result= blogclient.post(blog)
puts result