
We have already set up a method to retrieve the collection of rows. We can also append a new row at the end (see the add_row() method in Chapter 1). Now we want to be able to retrieve a single row. Following is the code to retrieve the contents of a particular row:

    # We will omit this context declaration for the remainder of the chapter
    context "row manipulations" do
      setup do
        @table = Table.new(@data, :headers => true)
      end
      
      test "can retrieve a row" do
        assert_equal ["George", 45,"photographer"], @table.row(2)
      end
    end


    class Table
    
      def row(i)
        rows[i]
      end
    end

What if we want to insert a new row in a particular position and not at the end? 

    test "can insert a row at any position" do
      @table.add_row(["Jane", 19, "shop assistant"], 2)
      assert_equal ["Jane", 19, "shop assistant"], @table.row(2)
    end
 
Instead of creating a brand new method for inserting a row at a particular position, we simply change the existing add_row() method to take an optional second argument representing the position where the new row should be inserted. If we don't send in a position, the new row will be appended at the end by default.
 
    class Table
      
      def add_row(new_row, pos=nil)
        i = pos.nil? ? rows.length : pos
        rows.insert(i, new_row)
      end
    end

To proceed with deleting a particular row from our table, we set up a test to check that a deleted row has actually been replaced:

    test "can delete a row" do
      to_be_deleted = @table.row(2)
      @table.delete_row(2)  
      assert_not_equal to_be_deleted, @table.row(2)
    end


    class Table
    
      def delete_row(pos)   
        @rows.delete_at(pos)
      end
    end

Next, we need to write a method to trigger a row-level transformation for altering all the data cells of that row in a user-defined way. In other words, we have to design our API in such a way it can accept the transformation code as an argument. This is where blocks come into play.

    test "transform row cells" do
      @table.transform_row(0) do |cell| 
        cell.is_a?(String) ? cell.upcase : cell
      end
      
      assert_equal ["TOM", 32, "ENGINEER"], @table.row(0)
    end


    class Table
    
      def transform_row(pos, &block)
        @rows[pos].map!(&block)
      end
    end

Here we take advantage of the Array#map! method - which can accept a block as an argument - and delegate the heavy lifting over to it.

There are other use cases where the API would need to respond to user-defined blocks. Say we want to reduce our table data to only contain records of people under 30. That would mean that we'd have to check every row for that condition (age under 30) and only keep those rows that meet this criteria. 

    test "reduce the rows to those that meet a particular conditon" do
      @table.select_rows do |row|
        row[1] < 30
      end
      assert !@table.rows.include?(["George", 45,"photographer"])
    end

Again, there's a handy Array method to accomplish this, namely Array#select!

    class Table
    
      def select_rows(&block)
        @rows.select!(&block)
      end
    end

So far so good. Our table implementation is starting to take shape. Let's implement the final set of requirements in the next chapter.
