# TODO: Replace CSV creation with FasterCSV
# TODO: Make it gracefully fall back to CSV if no FasterCSV is available
# TODO: Add error handling

# Adds a import_with_load_data_infile class method.
# this lets you import data using mysql "LOAD DATA INFILE"  
# This is about 30% faster than using ar-extensions bulk import
# 
# be careful, there's no validation or escaping here!
module ImportWithLoadDataInFile
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def import_with_load_data_infile(cols, vals, options = {})
      file = create_tempfile_for(vals)
      options[:local] = true if options[:local].nil? # default value
      sql = create_with_load_data_infile_statement(file.path, cols, options[:local])
      ActiveRecord::Base.connection.execute(sql)
      file.close # do not unlink the file, we need it later!
    end
    
    protected
    
    def create_tempfile_for(vals)
      tmpdir = Dir::tmpdir
      file = Tempfile.new('ImportWithLoadDataInfile', tmpdir)
      tmpdir_file = File.new(tmpdir)
      # fix permissions
      tmpdir_file.chmod(0755) rescue nil # do not barf if chmod fails
      file.chmod(0644)
      vals.each do |column_values|
        file.write '"' + line_for(column_values) + "\"\n"
      end
      file.flush
      return file
    end 
    
    # converts an array of column values into a csv string
    def line_for(column_values)
      column_values.map {|value| value_for(value) }.join('","')
    end 
    
    # converts a single column value to a string representation doing appropriate conversions
    def value_for(value)
      return value.to_s(:db) if value.kind_of?(Time) 
      return value.to_s(:db) if value.kind_of?(Date)
      return value.to_s
    end
    
    def create_with_load_data_infile_statement(file_path, cols, local = true)
      local_string = local ? "LOCAL " : ''
      column_list = cols.map(&:to_s).join(',')
      "LOAD DATA #{local_string}INFILE '#{file_path}' REPLACE INTO TABLE #{table_name} FIELDS TERMINATED BY ',' ENCLOSED BY '\"' (#{column_list});"
    end
  end
end
