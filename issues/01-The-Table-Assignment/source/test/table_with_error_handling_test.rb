# encoding: utf-8

require "test/unit"
require "contest"

require_relative "../table_with_error_handling"

class ErrorHandlingTest < Test::Unit::TestCase
  setup do
    @data = [["name",   "age", "occupation"  ],
             ["Tom",     32,   "engineer"    ],
             ["Beth",    12,   "student"     ],
             ["George",  45,   "photographer"],
             ["Laura",   23,   "aviator"     ],
             ["Marilyn", 84,   "retiree"     ]]
    
    @table = Table.new(@data, :headers => true)
  end
  
  context "[] out of bounds" do
    test "on row raises NoRowError" do
      assert_raise(Table::NoRowError) {
        @table[99, 0]
      }
    end
    
    test "on column raises NoColumnError" do
      assert_raise(Table::NoColumnError) {
        @table[0, 99]
      }
    end
  end
  
  context "column names" do
    test "raises NoColumnError when unknown column name" do
      assert_raise(Table::NoColumnError) {
        @table[0, "unknown column"]
      }
    end
    
    test "raises ArgumentError when adding a column with an existing name" do
      assert_raise(ArgumentError) {
        @table.add_column(["age", 10, 11, 12, 13, 14])
      }
    end
    
    test "raises ArgumentError when renaming a column to an existing name" do
      assert_raise(ArgumentError) {
        @table.rename_column("name", "age")
      }
    end
  end
  
  context "bad input raises ArgumentError" do
    test "when table is set with uneven row length" do
      assert_raise(ArgumentError) {
        Table.new([[1,2,3], [4,5], [6]])
      }
    end
    
    test "when adding a row with uneven length" do
      assert_raise(ArgumentError) {
        @table.add_row(["Greg"])
      }
    end
    
    test "when adding a column with uneven length" do
      assert_raise(ArgumentError) {
        @table.add_column(["short_column", "value"])
      }
    end
  end
  
  context "data corruption" do
    setup do
      @provided = [["header"], ["value"]]
      @pristine = Marshal.load(Marshal.dump(@provided))
    end
    
    test ".new doesn't corrupt provided data" do
      Table.new(@provided, :headers => true)
      
      assert_equal @pristine, @provided
    end
    
    test "a change on the initial data doesn't change the Table internals" do
      table = Table.new(@provided)
      @provided[0][0] = "different_header"
      
      assert_not_equal @provided, table.rows
    end
  end
end

class TableTest < Test::Unit::TestCase 
  setup do
    @data = [["name",   "age", "occupation"  ],
             ["Tom",     32,   "engineer"    ],
             ["Beth",    12,   "student"     ],
             ["George",  45,   "photographer"],
             ["Laura",   23,   "aviator"     ],
             ["Marilyn", 84,   "retiree"     ]]
  end
  
  test "can be initialized empty" do
    table = Table.new
    assert_equal [], table.rows
  end
  
  test "row can be appended after empty initialization" do
    table = Table.new
    table.add_row([1,2,3])
    assert_equal [[1,2,3]], table.rows
  end
  
  test "can be initialized with a two-dimensional array" do
    table = Table.new(@data)
    assert_equal @data, table.rows
    assert !table.header_support
  end
  
  test "first row converted into column names, if indicated" do
    table = Table.new(@data.dup, :headers => true)
    assert_equal @data[1..-1], table.rows
    
    assert table.header_support
    assert_equal({"name"=>0, "age"=>1, "occupation"=>2}, table.headers)
  end

  test "cell can be referred to by column name and row index" do
    table = Table.new(@data, :headers => true)
    assert_equal "Beth", table[1, "name"]
  end

  test "cell can be referred to by column index and row index" do
    table = Table.new(@data, :headers => true)
    assert_equal "Beth", table[1, 0]
  end
  
  
  context "row manipulations" do
    setup do
      @table = Table.new(@data, :headers => true)
    end

    test "can retrieve a row" do
      assert_equal ["George", 45,"photographer"], @table.row(2)
    end
  
    test "can insert a row at any position" do
      @table.add_row(["Jane", 19, "shop assistant"], 2)
      assert_equal ["Jane", 19, "shop assistant"], @table.row(2)
    end
  
    test "can delete a row" do
      to_be_deleted = @table.row(2)
      @table.delete_row(2)
      assert_not_equal to_be_deleted, @table.row(2)
    end
  
    test "transform row cells" do
      @table.transform_row(0) do |cell|
        cell.is_a?(String) ? cell.upcase : cell
      end
      assert_equal ["TOM", 32, "ENGINEER"], @table.row(0)
    end
  
    test "reduce the rows to those that meet a particular conditon" do
      @table.select_rows do |row|
        row[1] < 30
      end
      assert !@table.rows.include?(["George", 45,"photographer"])
    end
  end
  

  context "column manipulations" do
    setup do
      @table = Table.new(@data, :headers => true)
    end

    test "can access a column by its name" do
      assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],
                   @table.column("name")
    end

    test "can access a column by its index" do
      assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],
                   @table.column(0)
    end
  
    test "can rename a column" do
      @table.rename_column("name", "first name")
      assert_equal({"first name"=>0, "age"=>1, "occupation"=>2}, @table.headers)
    end
  
    test "can append a column" do
      to_append = ["location", "Italy", "Mexico", "USA", "Finland", "China"]
      @table.add_column(to_append)
      
      assert_equal({"name"=>0, "age"=>1, "occupation"=>2, "location"=>3},
                   @table.headers)
      assert_equal 4, @table.rows.first.length
    end

    test "can insert a column at any position" do
      to_append = ["last name", "Brown", "Crimson", "Denim", "Ecru", "Fawn"]
      @table.add_column(to_append, 1)
      
      assert_equal({"name"=>0, "last name"=>1, "age"=>2, "occupation"=>3},
                   @table.headers)
      assert_equal "Brown", @table[0,1]
    end
   
    test "can delete a column from any position" do
      @table.delete_column(1)
      assert_equal({"name"=>0, "occupation"=>1}, @table.headers)
      assert_equal ["Tom", "engineer"],    @table.row(0)
    end

    test "can run a transformation on a column which changes its content" do
      expected_ages = @table.column("age").map {|a| a+= 5 }
      @table.transform_columns("age") do |col|
        col += 5
      end
      assert_equal expected_ages, @table.column("age")
    end

    test "can select columns by some criteria" do
      table = Table.new([["item1", "item2", "item3", "item4", "item5"],
                         [3, 7, 4, 9, 2],
                         [4, 8, 2, 3, 1],
                         [0, 9, 3, 4, 6]
                         ],
                        :headers => true)
      
      table.select_columns do |col|
        col.inject(0, &:+) < 10
      end
      
      assert_equal 3, table.max_x
      assert_equal({"item1" => 0, "item3" => 1, "item5" => 2}, table.headers)
    end
  end
end
