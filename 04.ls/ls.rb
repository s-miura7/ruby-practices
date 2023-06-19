#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'etc'
opts = OptionParser.new

params = {}
opts.on('-l') { |v| params[:l] = v }
opts.on('-a') { |v| params[:a] = v }
opts.on('-r') { |v| params[:r] = v }
opts.parse!(ARGV)

COLUMNS = 3
BYTE_LENGTH = 5
directory_path = ARGV[0] || '.'

def get_file(path, option)
  if option[:r]
    Dir.glob('*', base: path, sort: true).reverse
  elsif option[:a]
    Dir.glob('*', File::FNM_DOTMATCH, base: path, sort: true)
  else
    Dir.glob('*', base: path, sort: true)
  end
end

FILE_TYPE = {
  'file' => '-',
  'directory' => 'd',
  'characterSpecial' => 'c',
  'fifo' => 'f',
  'link' => 'l',
  'socket' => 's'
}.freeze

FILE_PERMISSION = {
  '0' => '---',
  '1' => '--x',
  '2' => '-w-',
  '3' => '-wx',
  '4' => 'r--',
  '5' => 'r-x',
  '6' => 'rw-',
  '7' => 'rwx'
}.freeze

def get_permission(target)
  permission = ''
  file_type = File::Stat.new(target).ftype
  permission += FILE_TYPE[file_type]
  permission_base_eight = File::Stat.new(target).mode.to_s(8)
  three_digit = permission_base_eight[(permission_base_eight.length.to_i - 3)...permission_base_eight.to_i]
  three_digit.each_char { |c| permission += FILE_PERMISSION[c] }
  permission
end

def get_details(files_and_directories)
  files_and_directories.map do |file_or_directory|
    details_files_and_directories = {}
    permission = get_permission(file_or_directory)
    details_files_and_directories[:permission] = permission
    file_stat = File::Stat.new(file_or_directory)
    details_files_and_directories[:links] = file_stat.nlink.to_s.rjust(file_stat.nlink.to_s.length.to_i + 1)
    details_files_and_directories[:owner] = Etc.getpwuid(file_stat.uid).name.rjust(Etc.getpwuid(file_stat.uid).name.length.to_i + 1)
    details_files_and_directories[:group] = Etc.getgrgid(file_stat.gid).name.rjust(Etc.getgrgid(file_stat.gid).name.length.to_i + 1)
    details_files_and_directories[:byte_size] = file_stat.size.to_s.rjust(BYTE_LENGTH + 1)
    details_files_and_directories[:time] = file_stat.mtime.strftime('%m %d %H:%M').center(file_stat.mtime.strftime('%m %d %H:%M').length + 2)
    details_files_and_directories[:name] = file_or_directory
    details_files_and_directories
  end
end

def get_max_length(files_and_directories)
  files_and_directories.map(&:length).max
end

def organizing_arrays(file_name_length, files_and_directories, output_num)
  outputs = Array.new(COLUMNS) { [] }
  array_num = 0
  files_and_directories.each do |item|
    item = item.ljust(file_name_length * 2 - item.scan(/[^\x01-\x7E]/).size)
    outputs[array_num] << item
    array_num += 1 if (outputs[array_num].length % output_num).zero?
  end
  outputs
end

def output_file(output_num, files_and_directories)
  output_num.times do |time|
    COLUMNS.times do |column|
      next if files_and_directories[column][time].nil?

      print files_and_directories[column][time]
    end
    puts "\n"
  end
end

def output_file_with_l(files_and_directories)
  outputs = get_details(files_and_directories)
  puts "total #{outputs.flatten.length}"
  outputs.each do |file_or_directory|
    file_or_directory.each do |_key, value|
      print value
    end
    puts "\n"
  end
end

def output_file_with_no_option(temporary_outputs)
  max_file_length = get_max_length(temporary_outputs)
  # 一列に出力するファイルの数
  maximum_num = temporary_outputs.length / COLUMNS + 1
  outputs = organizing_arrays(max_file_length, temporary_outputs, maximum_num)
  output_file(maximum_num, outputs)
end

temporary_outputs = get_file(directory_path, params)
if params[:l]
  output_file_with_l(temporary_outputs)
else
  output_file_with_no_option(temporary_outputs)
end
