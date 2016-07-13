require 'net/ftp'
require 'zlib'

class HumanGenome  
  DOWNLOAD_DOMAIN = 'ftp.ncbi.nih.gov'

  def self.data_directory
    @data_directory ||= "#{File.dirname(__FILE__)}/data"
  end
  
  def self.tmp_directory
    @tmp_directory ||= "#{File.dirname(__FILE__)}/tmp"
  end
  
  def self.ensure_downloaded
    self.download_latest_data unless Dir.exists?(self.data_directory)
  end
  
  def self.download_latest_data
    self.ensure_fresh_directory(self.tmp_directory)
    self.ensure_fresh_directory(self.data_directory)
    
    ftp = Net::FTP.new(DOWNLOAD_DOMAIN)
    ftp.login

    self.chromosome_stems.each do |chromosome_stem|
      padded_stem_string = if chromosome_stem.is_a?(Integer)
        chromosome_stem.to_s.rjust(2,'0') 
      else
        chromosome_stem.to_s
      end
      
      # I don't understand this magic string yet:
      remote_path = "genomes/Homo_sapiens/CHR_#{padded_stem_string}/hs_ref_GRCh38.p7_chr#{chromosome_stem.to_s}.fa.gz"
      tmp_local_path = "#{self.tmp_directory}/chromosome_#{chromosome_stem}.fa.gz"
      local_path = "#{self.data_directory}/chromosome_#{chromosome_stem}.fa"
      
      puts "Downloading #{remote_path}"
      ftp.getbinaryfile(remote_path, tmp_local_path)
      
      puts "Unzipping #{tmp_local_path}"
      File.open(local_path, 'w') do |file|
        unzipped_contents = Zlib::GzipReader.open(tmp_local_path).read 
        file.write(unzipped_contents)
      end
    end
    
    self.cleanup_directory(self.tmp_directory)
  end
  
  def self.ensure_fresh_directory(directory_path)
    self.cleanup_directory(directory_path)
    FileUtils.mkdir(directory_path)
  end
  
  def self.cleanup_directory(directory_path)
    FileUtils.rm_r(directory_path) if Dir.exists?(directory_path)
  end
  
  def self.chromosome_stems
    @chromosome_stems ||= (1..22).to_a + ['X', 'Y', 'MT', 'Un']
  end
  
  attr_accessor :chromosomes
  
  def initialize
    load_local_data
  end
  
  def load_local_data
    @chromosomes = Hash.new
    HumanGenome.chromosome_stems.each do |chromosome_stem|
      local_path = "#{HumanGenome.data_directory}/chromosome_#{chromosome_stem}.fa"
      contents = File.read(local_path)
      chromosome = contents.split("\n")[1..-1].join
      @chromosomes[chromosome_stem] = chromosome
    end
    
    return
  end
  
  def ensure_downloaded; HumanGenome.ensure_downloaded; end
end
