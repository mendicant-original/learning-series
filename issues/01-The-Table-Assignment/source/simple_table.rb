# encoding: utf-8

class Table
  
  attr_reader :rows, :headers, :header_support
  def initialize(data = [], options = {})
    @header_support = options[:headers]
    @headers = @header_support ? data.shift : []
    @rows = data
  end

  def column_index(pos)
    i = @headers.index(pos)
    i.nil? ? pos : i
  end

  def [](row, col)
    col = column_index(col)
    rows[row][col]
  end

  def max_y
    rows[0].length
  end

  # Row Manipulations

  def add_row(new_row, pos=nil)
    i = pos.nil? ? rows.length : pos
    rows.insert(i, new_row)
  end

  def row(i)
    rows[i]
  end

  def delete_row(pos)
    @rows.delete_at(pos)
  end

  def transform_row(pos, &block)
    @rows[pos].map!(&block)
  end

  def select_rows(&block)
    @rows.select!(&block)
  end

  # Column Manipulations

  def column(pos)
    i = column_index(pos)
    @rows.map { |row| row[i] }
  end

  def rename_column(old_name, new_name)
    i = @headers.index(old_name)
    @headers[i] = new_name
  end

  def add_column(col, pos=nil)
    i = pos.nil? ? rows.first.length : pos
    if header_support
      @headers.insert(i, col.shift)
    end
    @rows.each do |row|
      row.insert(i, col.shift)
    end
  end

  def delete_column(pos)
    pos = column_index(pos)
    if header_support
      @headers.delete_at(pos)
    end
    @rows.map { |row| row.delete_at(pos) }
  end

  def transform_columns(pos, &block)
    pos = column_index(pos)
    @rows.each do |row|
      row[pos] = yield row[pos]
    end
  end

  def select_columns
    selected = []

    (0...max_y).each do |i|
      col = @rows.map { |row| row[i] }
      selected.unshift(i) unless yield col
    end

    selected.each do |pos|
      delete_column(pos)
    end
  end
   
end
