#!/usr/bin/env ruby

$:.unshift(File.expand_path("vendor/bundle/rubyzip-1.2.2/lib"))
$:.unshift(File.expand_path("vendor/bundle/ruby-progressbar-1.10.0/lib"))

require 'fileutils'
require 'zip'
require 'ruby-progressbar'

in_zip_or_folder = ARGV[0]
if in_zip_or_folder.nil? || (!File.file?(in_zip_or_folder) && !File.directory?(in_zip_or_folder))
  puts "ERRO: Pasta ou Arquivo inválido!"
  return
end

out_zip_name = ARGV[1]
if out_zip_name.nil?
  out_zip_name = File.basename(in_zip_or_folder, '.zip')
  puts "Nome do arquivo destino não informado, setado como: #{out_zip_name}"
end

chunk_mb = ARGV[2]
if chunk_mb.nil?
  chunk_mb = 50
  puts "Tamanho limite dos arquivos não informado, setado como: #{chunk_mb}mb"
end

base_dir = File.dirname(in_zip_or_folder)
out_zip_path = File.join(base_dir, out_zip_name)

def count_files_dir(dir_path)
  Dir.glob(File.join(dir_path, '**', '*')).select do |file|
    File.file?(file)
  end.count
end

def mb_to_bytes(mb = 0)
  mb.to_i * (2 ** 20)
end

def progress_bar(title, total)
  ProgressBar.create(
      :format => '%a%E %B %p%% %t',
      :title => title,
      :total => total
  )
end

def unzip_it(zip_path, destination_dir)
  Zip.default_compression = Zlib::BEST_COMPRESSION
  Zip::File.open(zip_path) do |zip_file|
    zip_name = File.basename(zip_file.name)
    progressbar = progress_bar("Descompactando #{zip_name}", zip_file.entries.size)
    zip_file.each do |zip_entry|
      next if zip_entry.name =~ /__MACOSX/ || zip_entry.name =~ /\.DS_Store/ || !zip_entry.file?
      filename = File.basename(zip_entry.name)
      entry_path = File.join(destination_dir, filename)
      FileUtils.rm_r(entry_path) if File.file?(entry_path)
      zip_entry.extract(entry_path)
      progressbar.increment
    end
    progressbar.finish unless progressbar.finished?
  end
  destination_dir
end

def zip_it(zip_path, files)
  FileUtils.rm_r(zip_path) if File.file?(zip_path)
  Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
    zip_name = File.basename(zip_path)
    progressbar = progress_bar("Compactando #{zip_name}", files.size)
    files.each do |file_path|
      next if file_path =~ /__MACOSX/ || file_path =~ /\.DS_Store/ || !File.file?(file_path)
      entry_name = File.basename(file_path)
      zipfile.add(entry_name, file_path)
      progressbar.increment
    end
    progressbar.finish unless progressbar.finished?
  end
  zip_path
end

def finish_tmp_file(tmp_path, zip_path, stream_file = nil, mb_limit = 0)
  tmp_size = File.size(tmp_path)
  if tmp_size >= mb_to_bytes(mb_limit)
    FileUtils.rm_r(zip_path) if File.file?(zip_path)
    FileUtils.mv tmp_path, zip_path
    FileUtils.rm_r(tmp_path) if File.file?(tmp_path)
    stream_file.close if stream_file
    return true
  end
  false
end

def add_file_to_stream(file_path, stream_file)
  stream_file.put_next_entry File.basename(file_path)
  stream_file.write File.read(file_path)
end

def package_it(out_zip_path, files_dir, split_in_mb = nil)
  return zip_it("#{out_zip_path}.zip", files_dir) if split_in_mb.nil?

  zip_counter = 0
  zip_path = nil
  tmp_path = nil
  stream_file = nil
  progressbar = progress_bar("...", count_files_dir(files_dir))
  zip_pool = []

  Dir.foreach(files_dir) do |file_name|
    file_path = File.join(files_dir, file_name)
    next if file_path =~ /__MACOSX/ || file_path =~ /\.DS_Store/ || !File.file?(file_path)

    if zip_path.nil?
      zip_counter += 1
      zip_path = "#{out_zip_path}_#{zip_counter}.zip"
      zip_dirname, zip_basename = ::File.split(zip_path)
      zip_pool << zip_basename
      tmp_path = Dir::Tmpname.create(zip_basename, zip_dirname) {}
      progressbar.title = "Compactando #{File.basename(zip_path)}"
      stream_file = Zip::OutputStream.new(tmp_path)
    end

    add_file_to_stream(file_path, stream_file)

    if finish_tmp_file(tmp_path, zip_path, stream_file, split_in_mb)
      zip_path = nil
    end

    progressbar.increment
  end

  finish_tmp_file(tmp_path, zip_path, stream_file)
  progressbar.finish if progressbar && !progressbar.finished?

  if zip_pool.size > 0
    puts "#{zip_pool.size} arquivos gerados:"
    zip_pool.each {|name| puts "-- #{name}"}
  end
end

if File.directory?(in_zip_or_folder)
  package_it(out_zip_path, in_zip_or_folder, chunk_mb)
else
  base_name = File.basename(in_zip_or_folder, '.zip')
  destionation_dir = File.join(base_dir, base_name)
  FileUtils.mkpath(destionation_dir) unless File.directory?(destionation_dir)
  unzip_it(in_zip_or_folder, destionation_dir)
  package_it(out_zip_path, destionation_dir, chunk_mb)
  FileUtils.rm_r(destionation_dir)
end