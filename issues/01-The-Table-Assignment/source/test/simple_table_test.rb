# encoding: utf-8

require "test/unit"
require "contest"

require_relative "../simple_table"

class TableTest < Test::Unit::TestCase 
  setup do
    @simple_data = [["name",  "age", "occupation"],
                    ["Tom", 32,"engineer"],
                    ["Beth", 12,"student"],
                    ["George", 45,"photographer"],
                    ["Laura", 23, "aviator"],
                    ["Marilyn", 84, "retiree"]]
    @simple_table = Table.new(@simple_data.dup, :headers => true)
  end
  
  test "can be initialized empty" do
    my_table = Table.new
    assert_equal [], my_table.rows
  end
  
  test "row can be appended after empty initialization" do
    my_table = Table.new
    my_table.add_row([1,2,3])
    assert_equal [[1,2,3]], my_table.rows
  end
  
  test "can be initialized with a two-dimensional array" do
    my_table = Table.new(@simple_data)
    assert_equal @simple_data, my_table.rows
    assert_equal [], my_table.headers
  end
  
  test "first row considered column names, if indicated" do
    assert_equal @simple_data[1..-1], @simple_table.rows
    assert_equal @simple_data[0], @simple_table.headers
  end

  test "cell can be referred to by column name and row index" do
    assert_equal "Beth", @simple_table[1,"name"]
  end

  test "cell can be referred to by column index and row index" do
    assert_equal "Beth", @simple_table[1, 0]
  end
  
  test "can insert a row at any position" do
    @simple_table.add_row(["Jane", 19, "shop assistant"], 2)
    assert_equal ["Jane", 19, "shop assistant"], @simple_table.row(2)
  end
  
  test "should be able to retrieve a row" do
    assert_equal ["George", 45,"photographer"], @simple_table.row(2)
  end
  
  test "should be able to delete a row" do
    to_be_deleted = @simple_table.row(2)
    @simple_table.delete_row(2)
    assert_not_equal to_be_deleted, @simple_table.row(2)
  end
  
  test "should update the transformed row cells" do
    @simple_table.transform_row(0) do |cell|
      cell.is_a?(String) ? cell.upcase : cell
    end
    assert_equal "TOM", @simple_table[0,"name"]
  end
  
  test "should be able to reduce the rows of the table to those that meet a particular conditon" do
    @simple_table.select_rows do |row|
      row[1] < 30
    end
    assert !@simple_table.rows.include?(["George", 45,"photographer"])
  end
  
  test "can access a column by its name" do
    assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],   @simple_table.column("name")
  end

  test "can access a column by its index" do
    assert_equal ["Tom", "Beth", "George", "Laura", "Marilyn"],   @simple_table.column(0)
  end
  
  test "can rename a column" do
    @simple_table.rename_column("name", "first name")
    assert_equal ["first name", "age", "occupation"], @simple_table.headers
  end
  
  test "can append a column" do
    to_append = ["location", "Italy", "Mexico", "USA", "Finland", "China"]
    @simple_table.add_column(to_append)
    assert_equal ["name", "age", "occupation", "location"], @simple_table.headers
    assert_equal 4, @simple_table.rows.first.length
  end


  test "can insert a column at any position" do
    to_append = ["last name", "Brown", "Crimson", "Denim", "Ecru", "Fawn"]
    @simple_table.add_column(to_append, 1)
    assert_equal ["name", "last name", "age", "occupation"], @simple_table.headers
    assert_equal "Brown", @simple_table[0,1]
  end
   
  test "can delete a column from any position" do
    @simple_table.delete_column(1)
    assert_equal ["name", "occupation"], @simple_table.headers
    assert_equal ["Tom", "engineer"], @simple_table.row(0)
  end

  test "can run a transformation on a column which changes its content" do
    expected_ages = @simple_table.column("age").map {|a| a+= 5 }
    @simple_table.transform_columns("age") do |col|
      col += 5
    end
    assert_equal expected_ages, @simple_table.column("age")
  end

  test "can select columns by some criteria" do
    @simple_table.select_columns do |col|
      col.all? {|c| Numeric === c }
    end
    assert_equal 1, @simple_table.row(0).length
    assert_equal ["age"], @simple_table.headers
  end
end
