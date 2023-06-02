#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

opts = OptionParser.new
params = {}
opts.on('-r') { |v| params[:r] = v }
opts.parse!(ARGV)

COLUMNS = 3

directory_path = ARGV[0] || '.'

def get_file(path, option)
  if option[:r]
    Dir.glob('*', base: path, sort: true).reverse
  else
    Dir.glob('*', base: path, sort: true)
  end
end

def get_max_length(files_and_directories)
  files_and_directories.map(&:length).max
end

def organizing_arrays(file_name_length, files_and_directories, columns, output_num)
  outputs = Array.new(columns) { [] }
  array_num = 0
  files_and_directories.each do |item|
    outputs[array_num] << item.ljust(file_name_length + 1)
    array_num += 1 if (outputs[array_num].length % output_num).zero?
  end
  outputs
end

def output_file(output_num, columns, files_and_directories)
  output_num.times do |time|
    columns.times do |column|
      print files_and_directories[column][time]
    end
    puts "\n"
  end
end

temporary_outputs = get_file(directory_path, params)
max_file_length = get_max_length(temporary_outputs)
# 一列に出力するファイルの数
maximum_num = temporary_outputs.length / COLUMNS + 1
outputs = organizing_arrays(max_file_length, temporary_outputs, COLUMNS, maximum_num)
output_file(maximum_num, COLUMNS, outputs)

