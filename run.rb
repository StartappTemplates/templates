#!/usr/bin/env ruby

require 'fileutils'
require 'json'

ARGV.each do |arg|
  case arg
    when '-dev','--dev' then
      @dev_mode = true
  end
end

@templates_dist = 'file:///root/templates/dist/'

file = File.read('cartridges.json')
data_hash = JSON.parse(file)

system 'rm -rf dist'
system 'rm -rf tmp'
system 'rm -rf final'
system 'mkdir -p tmp'
system 'mkdir -p final'

data_hash.each do |lang|

  lang.each do |cartridges|

    @lang = cartridges[0]

    #copy cartridge files
    system "cp -R .source tmp/#{@lang}/"

    #copy template files to tmp
    system "cp -R .templates/#{@lang} tmp/#{@lang}/localization"

    system "mkdir -p final/#{@lang}"

    #create config file
    system "echo 'DEFAULT_APP_TEMPLATES=' > final/#{@lang}/config"

    cartridges[1].each do |cartridge|


      @name = cartridge['name']
      @path = cartridge['path']
      @package_files = cartridge['package_files']
      @template = cartridge['template']
      @versions = cartridge['versions']

      @versions.each do |version|

        @version = ''
        @version = version

        @repo_path = "#{@name}-#{version}|#{@templates_dist}#{@lang}/#{@name}-#{version}.git "
        #puts "#{@repo_path}"
        system "echo $(cat final/#{@lang}/config)'#{@repo_path}' > final/#{@lang}/config"

        #prepare template file for each language and version
        template_file = "tmp/#{@lang}/localization/#{@name}-#{version}/index.html"
        template_content = open(template_file).read()
        template_content.gsub! '{{name}}', "#{@name}"
        File.open(template_file, 'w') { |file| file.write(template_content) }

        #patch cartridge file
        cartridge_file = "tmp/#{@lang}/#{@path}#{@template}"
        cartridge_content = open(cartridge_file).read()
        cartridge_content.gsub! '{{HTML_CONTENT}}', template_content
        File.open(cartridge_file, 'w') { |file| file.write(cartridge_content) }

        system "mkdir -p final/#{@lang}/#{@name.downcase}-#{version}"

        @package_files.each do |argument|
          @file = "tmp/#{@lang}/#{@path}#{argument}"

          system "cp -R #{@file} final/#{@lang}/#{@name.downcase}-#{version}/"
        end
      end

    end
  end
end

system 'rm -rf tmp'

system './create_bare_repos.sh'

if @dev_mode
  puts 'All cartridges were patched in "final"'
else
  # system 'rm -rf final'
end

puts 'All bare repos were created in "dist"'

