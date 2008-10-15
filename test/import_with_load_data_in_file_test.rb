#!/usr/bin/env ruby
require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'import_with_load_data_in_file'

# support ActiveRecord class, I test ImportWithLoadDataInFile methods here
class Foo < ActiveRecord::Base
  include ImportWithLoadDataInFile
end

# reopen the module and make methods public for testing
module ImportWithLoadDataInFile
  module ClassMethods
    public :create_tempfile_for
    public :create_with_load_data_infile_statement
    public :value_for
  end 
end 

class ImportWithLoadDataInFileTest < Test::Unit::TestCase
  def setup 
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migration.create_table :foos do |t|
      t.string :name      
      t.string :surname
      t.integer :age
    end
    ActiveRecord::Migration.verbose = true
  end     
  
  def teardown 
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Migration.drop_table :foos
    ActiveRecord::Migration.verbose = true
  end
  
  def test_should_respond_to_import_with_load_data_infile
    assert Foo.respond_to?(:import_with_load_data_infile)
  end
    
  def test_should_create_a_temp_file_with_the_csv_content
      # cols = [:name, :surname, :age]
      vals = [ ["paolo", "dona", "29"],
               ["ciccio", "pasticcio", "25"]]
    
      expected_content = <<-END
"paolo","dona","29"
"ciccio","pasticcio","25"
END

    file = Foo.create_tempfile_for(vals)
    assert_equal expected_content, IO.read(file.path)
  end

  def test_should_convert_time_values_to_the_DB_representation
    vals = [["paolo",Time.parse('Aug 12, 2008'),"29"]]
  
    expected_content = <<-END
"paolo","2008-08-12 00:00:00","29"
END

    file = Foo.create_tempfile_for(vals)
    assert_equal expected_content, IO.read(file.path)
  end

  def test_should_convert_times
    assert_equal "2008-12-12 00:00:00", Foo.value_for(Time.parse('12 Dec, 2008'))
  end 
  
  def test_should_import_data
    cols = [:name, :surname, :age]
    vals = [ ["paolo", "dona", "29"],
             ["ciccio", "pasticcio", "25"]]
    
    Foo.import_with_load_data_infile cols, vals
    assert_equal 2, Foo.count
      
    assert !Foo.find_by_name_and_surname_and_age('paolo', 'dona', 29).nil? 
    assert !Foo.find_by_name_and_surname_and_age('ciccio', 'pasticcio', 25).nil? 
  end
    
  def test_should_import_data_with_local_turned_off
    cols = [:name, :surname, :age]
    vals = [ ["paolo", "dona", "29"],
             ["ciccio", "pasticcio", "25"]]
    
    Foo.import_with_load_data_infile cols, vals, :local => false
    assert_equal 2, Foo.count
      
    assert !Foo.find_by_name_and_surname_and_age('paolo', 'dona', 29).nil? 
    assert !Foo.find_by_name_and_surname_and_age('ciccio', 'pasticcio', 25).nil? 
  end
 
  def test_should_generate_the_correct_import_statement
    expected = "LOAD DATA LOCAL INFILE 'fake.txt' REPLACE INTO TABLE foos FIELDS TERMINATED BY ',' ENCLOSED BY '\"' (col1,col2);"
    assert_equal expected, Foo.create_with_load_data_infile_statement('fake.txt', [:col1,:col2]) 
  end 
  
  def test_should_generate_the_correct_import_statement_with_local_turned_off
    expected = "LOAD DATA INFILE 'fake.txt' REPLACE INTO TABLE foos FIELDS TERMINATED BY ',' ENCLOSED BY '\"' (col1,col2);"
    assert_equal expected, Foo.create_with_load_data_infile_statement('fake.txt', [:col1,:col2], false) 
  end 
end
