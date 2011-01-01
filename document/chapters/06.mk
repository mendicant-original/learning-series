06 lucasefe submission
======================

Although it works and has a fairly clean API, the solution presented above is by no means perfect. We have already mentioned the somewhat awkward access to columns. Another, just as serious problem is that all the code for the entire table lives in a single class, which is a code smell that indicates a violation of the Separation of Concerns principle.

Generally speaking a "concern" is some idea about what a piece of software has to do and different concerns should be handled by different parts of the software. The ideal is always to organize code into small, tightly focused sections, which makes any program both more readable and easier to maintain.

The Table class has some separation built-in by sporting short, focused methods. While this is a first step in the right direction, there should be other ways to break out functionality into separate, non-overlapping classes. This is however not as easy as it seems. Obvious attempts might include separating classes for rows and columns, but this will prove difficult because of the tight coupling between them. The coupling in question derives from the fact that they are essentially just different perspectives on the same data set. 

Here, we're going to discuss a solution that manages to treat rows and columns as wholly separate objects, but without duplicating the data set. The trick is that they don't hold the actual data values, but delegate that responsibility to a Cell class. 

Rows, Colums and Cells
----------------------

How exactly is this behavior accomplished? Rows and columns are instances of the same class, namely Bricks::Index.

When the Table class gets initialized the rows and columns are populated with the same Cell objects, but are otherwise transposed versions of each other. The cells are the objects that actually store the data value, which makes the rows and columns indexed references to the cells. As a result, if you change the value of a Cell object through the rows, that same change will be reflected in the columns. We'll take a closer look at the Bricks::Index implementation in a few moments.

Upon initializing the Bricks::Table object, both @rows and @columns are being initialized and the seed data sent into the constructor seems to be processed row by row in the #add_row method. 

  module Bricks
    class Table
      # code omitted

      attr_reader :rows, :columns
      def initialize(*args)
        @rows    ||= Bricks::Index.new
        @columns ||= Bricks::Index.new
      
        # code to extract options and to set column headers omitted
        data = args.first.dup   # to avoid alter original data  

        data.each_with_index do |row, index|
          add_row row
        end
      end

      def add_row(new_row)
        add_and_update(new_row, rows, columns)
      end

      # code omitted
    end
  end

As you can see in the code above, the rows are immediately sent on to a method called #add_and_update that also takes the columns into account. Digging further into the code reveals that the #add_and_update method can handle both adding rows or adding columns just by switching out which of the two is considered to be the primary or the secondary target of the operation.

    module Bricks
      class Table
        # code omitted
        private

        def add_and_update(array, primary, secondary)
          new_array = []
          with_cells_in(array) do |cell, index|
            new_array << cell 
            secondary[index] ||= []
            secondary[index] << cell
          end
          primary << new_array
        end

        def with_cells_in(array)
          array.each_with_index do |value, index| 
            yield(build_cell(value), index)
          end
        end

        def build_cell(value)
          value.kind_of?(Bricks::Cell) ? value : Bricks::Cell.new(value) 
        end
      end
    end

Similarly, all pertinent operations (adding, inserting and deleting) are mirrored in both storage options and handled by the same private helper method, i.e. #delete_row_at and #delete_column_at both forward calls to #delete_at_and_update.

Let's play around with this on irb to demonstrate some of the advantages of this approach:

    >> data = [[1,2,3], [4,5,6], [7,8,9]]
    >> table = Bricks::Table.new(data)
    => #<Bricks::Table:0x191388 @options={}, @rows=[[1, 2, 3], [4, 5, 6], [7, 8, 9]], @columns=[[1, 4, 7], [2, 5, 8], [3, 6, 9]]> 

The mirroring of rows and columns affords very easy access to columns by simple array methods, such as:

    >> table.columns[0]
    => [2,4,7]

Also, changing the Cell value through rows will automatically change the value in the columns and vice versa:

    >> table.rows[0].map {|i| i.value = i.value*2}
    => [2, 4, 6] 
    >> table.rows
    => [[2, 4, 6], [4, 5, 6], [7, 8, 9]] 
    >> table.columns
    => [[2, 4, 7], [4, 5, 8], [6, 6, 9]]

To better understand how the Bricks::Index class is constructed, consider the following snippet from its initializer:

    module Bricks
      class Index < DelegateClass(Array)

        def initialize
          super(Array.new)
        end

        # code omitted
      end
    end

The most obvious feature is the use of DelegateClass(Array). Simply speaking, this lets Bricks::Index instances delegate methods not defined by the class itself to an internal array object. For a detailed explanation on how it works, see the following aside.


<h6 title="The DelegatorClass">
Under the hood DelegateClass is really just another method call and just like the class keyword returns a class object.

The class returned by DelegateClass(Array) is will delegate all methods defined by Array to an internal array object that should be passed to the initialize method. This object is created in the Bricks::Index initialize method and passed to the superclass via super(Array.new).

The Bricks::Index class can override array methods and also implement additional methods to define different behaviors.

Note that even though we seem to be using inheritance, we don't actually "inherit" directly from Array. Rather than stating that Bricks::Index is a special form of Array, It would be more precise to say that Bricks::Index is a Delegator and has an Array.
</h6>


Reading vs. Writing Operations
------------------------------

One of the major gripes we had with the solution we walked through step by step was the difficult access to columns, meaning that every time we had to retrieve a column, we needed to iterate through the rows and fetch the row item that corresponds to the column index in question.

Lucasefe's found a neat solution to that particular problem by storing the columns separately (but without duplicating the data set). However, this comes with a cost. Any operation that modifies the table - adding, inserting, deleting, filtering - becomes more processing intensive. Rows and columns need to be manually synched to each other, which effectively causes a "writing overhead".

One potential drawback is that this approach requires the creation of x * y Cell objects, whereby x is the number of rows and y the number of columns. This could lead to memory problems with very large tables.

Data Corruption
---------------

If you follow the code closely you may notice that a filtering of rows using the Bricks::Index#select! method would leave the columns unchanged. This unimplemented feature could easily be introduced if we were to devise a method responsible for safely executing the #select! operation, which would require proper synching with the alternate data storage. However, this omission points to a bigger issue altogether. Since the Brick::Index class exposes all the methods defined by Array, the user could cause accidental data corruption, for example by bypassing the intended API methods and working with array methods directly.