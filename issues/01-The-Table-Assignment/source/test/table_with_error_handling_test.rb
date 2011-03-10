# encoding: utf-8

require "test/unit"
require "contest"

require_relative "../table_with_error_handling"
# require_relative "simple_test_case"

class ErrorHandlingTest < Test::Unit::TestCase
  setup do
    @data = [["name",   "age", "occupation"  ],
             ["Tom",     32,   "engineer"    ],
             ["Beth",    12,   "student"     ],
             ["George",  45,   "photographer"],
             ["Laura",   23,   "aviator"     ],
             ["Marilyn", 84,   "retiree"     ]]
  end
  
  context "out of bounds indices" do
    setup do
      @table = Table.new(@data, :headers => true)
    end

    test "raises NoRowError" do
      assert_raise(Table::NoRowError) {
        @table[99, 0]
      } 
    end
  end
end
