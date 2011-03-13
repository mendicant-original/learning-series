In a perfect world, we could probably be done at this point. However, we have so far completely ignored an important aspect, namely dealing with potential errors.

We start with mimicking errors that could occur when accessing table data if non-existent rows or columns are being referenced. We can call them "out of bounds" errors. Consider the following scenario:

    >> table = Table.new(@data)
    >> table[99, 99]
    => NoMethodError: undefined method `[]' for nil:NilClass

As a reminder, here is the code that is presently unprepared to handle such a test case:

    class Table

      def [](row, col)
        col = column_index(col)
        rows[row][col]
      end
      
    end

If the referenced row (rows[row]) is out of bounds, then nil gets returned. This is in itself something that you might want to handle with either an error or a warning (or else accept that nil gets returned in such cases). If we attempt to retrieve a particular column in that non-existent row, however, we have an unhandled NoMethodError on our hands.

A simple fix could involve checking the requested index before attempting to retrieve the cell. The code below also demonstrates how one might set up and use custom error classes.

    class Table
    
      NoRowError = Class.new(StandardError)

      def [](row, col)
        check_row_index(row)
        col = column_index(col)
        rows[row][col]
      end

      def max_x
        @rows.length
      end

      def check_row_index(pos)
        unless (-max_x..max_x).include?(pos) 
          raise NoRowError, "The row index is out of range"
        end
      end
    end

This leaves Table#[] with mixed behavior when a row or column is out of bounds. For a row it will return an error and for a column it will return nil. Dealing with columns means that we need to take column names into account. In the next section, we take care of making the Table#[] behavior consistent.

Column names
------------

Since columns can be referenced either by their index or by their name, we could encounter nonexistent column names, as in:

    >> table[2, "bad_column"]
    => TypeError: can't convert String into Integer

Or, what if we were to insert or rename a column using a name that is already taken:

    >> table.add_column(["age", 10, 11, 12, 13, 14])
    >> table.headers
    => ["name", "age", "occupation", "age"]
    >> table[2, "age"]
    => 45

    >> table.rename_column("name", "age")
    >> table.headers
    => ["age", "age", "occupation", "age"]
    >> table[2, "age"]
    => George

To handle the case of referencing a column that doesn't exist, we can employ a similar strategy as the one we used for the rows. We can intercept the method that determines the numeric index of the column based on it being either a string or an integer. 

To avoid duplicate column names, we could just opt to check the @headers array when appropriate. Ruby, however, provides a more elegant way to deal with this problem. Changing the internal representation of @headers from an array to a hash facilitates avoiding duplicate names, since hashes don't allow for duplicate keys.

Here then is the code to guard against both potential sources of error:

    class Table
 
      def initialize(data = [], options = {})
        @header_support = options[:headers] 
        set_headers(data.shift) if @header_support
        @rows = data
      end

      def set_headers(header_names)
        @headers = {}
        header_names.each_with_index do |item, index|
          @headers[item] = index
        end
      end

      def max_y
        rows[0].length
      end

      def column_index(pos)
        pos = @headers[pos] || pos
        check_column_index(pos)
        return pos
      end

      def rename_column(old_name, new_name)
        check_header_names(new_name)
        @headers[new_name] = @headers[old_name]
        @headers.delete(old_name)
      end

      def add_column(col, pos=nil)
        i = pos.nil? ? rows.first.length : pos
        
        if header_support
          header_name = col.shift
          check_header_names(header_name)
          @headers.each { |k,v| @headers[k] += 1 if v >= i }
          @headers[header_name]  = i
        end
        
        @rows.each do |row|
          row.insert(i, col.shift)
        end
      end

page_break

      def delete_column(pos)
        pos = column_index(pos)
        
        if header_support
          header_name = @headers.key(pos)
          @headers.each { |k,v| @headers[k] -= 1 if v > pos }
          @headers.delete(header_name)
        end
        
        @rows.map {|row| row.delete_at(pos) }
      end

    private

      def check_header_names(name)
        raise ArgumentError, "Name already taken" if @headers[name]
      end

      def check_column_index(pos)
        unless (-max_y..max_y).include?(pos)
          raise NoColumnError,
                "The column does not exist or the index is out of range"
        end
      end
   
    end

Handling bad input
-------------------

In a table we expect all rows to have the same length and also all columns to have the same number of elements. Now, we turn our attention to input that does not conform to this basic expectation.

Generally speaking, there are two main courses of action in dealing with bad input: either reject it by raising an error or adjust the input so as to bring it back into the fold. 

One way to change rows and columns so that they have the expected length might be to pad the short ones and truncate the ones that are too long. When it comes to rows, we might get away with this strategy, but padding short columns could have some undesired side effects. In tables with header support, for instance, we assume the first element to be the header name. Should the header not be included in the new column, then the padding approach will cause a missing header to "fail silently": the first element will be appointed as the header, while the last element will be supplied by padding. 

Truncating rows/columns that are too long leaves one with an uneasy feeling, even if the truncation is accompanied by a warning. 

Considering all these issues with truncation/padding, we will instead raise an exceptions upon encountering rows or columns with unexpected lengths.

    class Table

      def initialize(data = [], options = {})
        check_type(data)
        data.each do |row|
          check_type(row)
          check_length(row, data.first.length, "Inconsistent rows length")
        end
        
        @header_support = options[:headers]
        set_headers(data.shift) if @header_support
        
        @rows = data
      end

      def add_row(new_row, pos=nil)
        check_type(new_row)
        check_length(new_row, max_y, "Inconsistent row length") unless @rows.empty?
        
        i = pos.nil? ? rows.length : pos
        rows.insert(i, new_row)
      end
   
   
      def add_column(col, pos=nil)
        check_type(col)
        check_length(col, max_x+1, "Inconsistent column length")
        
        i = pos.nil? ? rows.first.length : pos

        if header_support
          header_name = col.shift
          check_header_names(header_name)
          @headers.each { |k,v| @headers[k] += 1 if v >= i }
          @headers[header_name]  = i
        end

        @rows.each do |row|
          row.insert(i, col.shift)
        end
      end

      private

      def check_type(data)
        raise(ArgumentError, "Input is not an array") unless Array === data
      end

      def check_length(data, expected, msg="Input length is inconsistent")
        raise(ArgumentError, msg) unless data.length == expected
      end

    end

page_break

Data corruption
---------------

The user of our API can at any time inadvertently corrupt the table internals by tinkering with the provided data. Conversely, changes initiated through the table will also affect the provided data. 

The source of this issue lies in the fact that, in Ruby, variables hold references to objects, rather than being the objects themselves. As such, if the same object is referenced by more than one variable, we need to keep in mind that changes made to the object will be exposed regardless of which variable we chose to reference the object by. Here's a simple example to illustrate the point:

    >> person1 = "Tim"
    >> person2 = person1 
    >> person1[0] = 'J' 

    >> puts "person1 is #{person1}" 
    => person1 is Jim
    >> puts "person2 is #{person2}" 
    => person2 is Jim 

So, in our case, when we initialize a new Table we are setting the @rows variable to reference the same two-dimensional array as @data does. Here you can see that when we remove the first array as headers, we are also altering @data:

    >> @data = [["name",  "age", "occupation"],
                ["Tom", 32,"engineer"],
                ["Beth", 12,"student"],
                ["George", 45,"photographer"],
                ["Laura", 23, "aviator"],
                ["Marilyn", 84, "retiree"]]
    >> table = Table.new(@data, :headers => true)
    >> @data
    => [["Tom", 32,"engineer"], 
        ["Beth", 12,"student"], 
        ["George", 45,"photographer"],
        ["Laura", 23, "aviator"],
        ["Marilyn", 84, "retiree"]]

We can change the initialize method in order to avoid damaging the data provided by the user:

    class Table

      def initialize(data = [], options = {})
        # code omitted
        if options[:headers]
          @headers = data[0]
          @rows    = data[1..-1]
        else
          @headers = []
          @rows    = data
        end
      end
  
    end

While this approach doesn't change the provided data, data corruption can still happen. Here is another example of how altering @data will be reflected when we access the Table instance:

    >> table = Table.new(@data)
    >> @data[2][2] = "king of the world"
    >> table[2, 2]
    => "king of the world"

Let's say that to prevent accidental data corruption we want to somehow duplicate the provided data when we initialize the table. We might try to use Object#dup to accomplish this.

    class Table

      def initialize(data = [], options = {})
        # code omitted
        @rows = data.dup
      end
      
    end

Simple, isn't it? Except that this doesn't solve our problem. The behavior from the previous example remains.

    >> table = Table.new(@data)
    >> @data[2][2] = "king of the world"
    >> table[2, 2]
    => "king of the world"

Let's examine the dup() method a little closer:

page_break

<h6 title="From the Pickaxe book: dup()">
dup()

Produces a shallow copy of obj — the instance variables of obj are copied, but not the objects they reference. dup copies the tainted state of obj. See also the discussion under Object#clone.

In general, dup duplicates just the state of an object, while clone also copies the state, any associated singleton class, and any internal ﬂags (such as whether the object is frozen). The taint status is copied by both dup and clone. 
</h6>

So if we dup() the data that's passed to our initialize method before we assign it to Table#rows, the outer array that @rows points to is indeed a different object from the outer array held in @data. However, Table#rows and @data are still both referencing the same internal arrays, meaning the actual rows. To elucidate:

    >> table = Table.new(@data)
    >> table.rows.object_id    # note that the output is run specific
    => 2151823700  
    >> @data.object_id
    => 2151823780

    >> table.row(0).object_id
    => 2151825160
    >> @data[0].object_id
    => 2151825160


The only really reliable way to create a brand new object when we assign it to another variable is marshaling. 

<h6 title="From the Pickaxe book: Marshaling">
Marshaling is the ability to serialize objects, letting you store them somewhere and reconstitute them when needed.

[.....]

Saving an object and some or all of its components is done using the method Marshal.dump. Typically, you will dump an entire object tree starting with some given object. Later, you can reconstitute the object using Marshal.load.
</h6>

    class Table

      def initialize(data = [], options = {})
        check_type(data)
        data.each do |row|
          check_type(row)
          check_length(row, data.first.length, "Inconsistent rows length")
        end

        @header_support = options[:headers] 

        @rows = Marshal.load(Marshal.dump(data))
        set_headers(@rows.shift) if @header_support
      end
      
    end

We use Marshal.dump to output a string representation of the object tree referenced by "data" and then use this string as the input for Marshal.load which reconstructs the full object tree. Now there is no cross-reference between @data and the table @rows. We can also say that the Table.new method is side-effect free:

    >> table = Table.new(@data, :headers => true)
    >> @data[2][2] = "king of the world"
    >> table[2, 2]
    => "photographer"
    >> @data[0]
    => ["name", "age", "occupation"]

Unfortunately this method is also not without drawbacks. Apart from the time that it takes to marshall and unmarshall the seed data, we are temporarily storing two copies of the same nested array.

This technique can also be applied when adding rows and columns. You may find this improved implementation complete with tests here: https://github.com/rmu/learning-series/tree/master/issues/01-The-Table-Assignment/source

While this implementation is more robust than the one from the last chapter there's still room for improvement. In the following chapters we'll take a look at some interesting student submissions.
