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
      sql = create_with_load_data_infile_statement(file.path, cols)
      ActiveRecord::Base.connection.execute(sql)
    end
    
    protected
    
    def create_tempfile_for(vals)
      file = Tempfile.new('ImportWithLoadDataInfile')
      file.chmod(0644)
      # puts file.path
      vals.each do |column_values|
        file.write '"' + line_for(column_values) + "\"\n"
      end
      file.close # do not unlink the file, we need it later!
      file 
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
    
    def create_with_load_data_infile_statement(file_path, cols)
      column_list = cols.map(&:to_s).join(',')
      "LOAD DATA LOCAL INFILE '#{file_path}' REPLACE INTO TABLE #{table_name} FIELDS TERMINATED BY ',' ENCLOSED BY '\"' (#{column_list});"
    end
  end
end