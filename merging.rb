#!/usr/bin/env ruby                                                                                       
#                                                                                                         
# synopsis                                                                                                
#                                                                                                         
#   ruby merge_locales.rb config/locales <language-code>.yml

require 'yaml'
require 'rubygems'
require 'highline/import'

::Hash.class_eval do
  class MergeConflict < StandardError; end
  def deep_merge(other, &bloc)
    other.keys.inject(dup) do |result, key|
      begin
        case result[key]
        when Hash
          if other[key].is_a?(Hash)
            result[key] = result[key].deep_merge(other[key], &bloc)
            result
          else
            raise MergeConflict
          end
        when nil then result.merge key => other[key]
        else
          raise MergeConflict
        end
      rescue MergeConflict
        if bloc.nil?
          result[key] = other[key]
        else
          result[key] = bloc.call(result, other, key)
        end
        result
      end
    end
  end
end

result = ARGV.inject({}) do |result, path|
  files = [path] if File.file?(path) && path.match(/\.yml$/)
  files ||= Dir.glob( File.join(path, '**', '*'+ARGV[1]+'.yml')).to_a
  files.inject(result) do |inner_result, file|
    warn "loading #{file}"
    yaml = File.open(file) { |yf| YAML::load(yf) }
    inner_result.deep_merge(yaml) do |res, other, key|
      if other[key].nil?
        res[key]
      elsif res[key] == other[key]
        res[key]
      else
        warn "Conflict on key: '#{key}' of '#{file}'"
        warn "  1. #{res[key].inspect} (encoding: #{res[key].encoding})"
        warn "  2. #{other[key].inspect} (encoding: #{res[key].encoding})"
        select = ask('')
        case select
        when '1' then res[key]
        when '2' then other[key]
        end
      end
    end
  end
end

YAML.dump(result, STDOUT)
# File.open("Translation_project/combined_language_yaml_files/"+ARGV+".yml", "w") { |file| file.write(result.to_yaml) }