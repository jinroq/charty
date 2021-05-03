class VectorPandasTest < Test::Unit::TestCase
  include Charty::TestHelpers

  def setup
    pandas_required

    @series = Pandas::Series.new([1, 2, 3, 4, 5], dtype: :float64)
    @vector = Charty::Vector.new(@series)
  end

  def test_length
    assert_equal(5, @vector.length)
  end

  def test_name
    values = [@vector.name]
    @vector.name = "abc"
    values << @vector.name
    assert_equal([nil, "abc"], values)
  end

  sub_test_case("#index") do
    sub_test_case("without explicit index") do
      def test_index
        assert_equal([0, 1, 2, 3, 4], @vector.index.to_a)
      end
    end

    sub_test_case("with string index") do
      def test_index
        @series.index = ["a", "b", "c", "d", "e"]
        assert_equal(["a", "b", "c", "d", "e"], @vector.index.to_a)
      end
    end

    sub_test_case(".name") do
      def test_index_name
        values = [@vector.index.name]
        @vector.index.name = "abc"
        values << @vector.index.name
        assert_equal([nil, "abc"], values)
      end
    end
  end

  sub_test_case("#[]") do
    sub_test_case("without explicit index") do
      def test_aref
        assert_equal([
                       2,
                       4
                     ],
                     [
                       @vector[1],
                       @vector[3]
                     ])
      end
    end

    sub_test_case("with string index") do
      def test_aref
        @series.index = ["a", "b", "c", "d", "e"]
        assert_equal([
                       2,
                       3,
                       4,
                       5
                     ],
                     [
                       @vector[1],
                       @vector["c"],
                       @vector["d"],
                       @vector[4]
                     ])
      end
    end
  end

  test("#to_a") do
    assert_equal([1, 2, 3, 4, 5],
                 @vector.to_a)
  end

  sub_test_case("#numeric?") do
    data(
      "for numeric array"                  => { array: [1, 2, 3, 4, 5]       , result: true },
      "for string array"                   => { array: ["abc", "def", "xyz"] , result: false },
      "for numeric array with nil at head" => { array: [nil, 1, 2, 3]        , result: true },
      "for string array with nil at head"  => { array: [nil, "abc", "xyz"]   , result: false },
    )
    def test_numeric(data)
      array, result = data.values_at(:array, :result)
      series = Pandas::Series.new(array)
      vector = Charty::Vector.new(series)
      assert_equal(result, vector.numeric?)
    end
  end

  sub_test_case("#categorical?") do
    data(
      "for numeric array"                  => [1, 2, 3, 4, 5],
      "for string array"                   => ["abc", "def", "xyz"],
      "for numeric array with nil at head" => [nil, 1, 2, 3],
      "for string array with nil at head"  => [nil, "abc", "xyz"]
    )
    def test_categorical_with_noncategorical(data)
      series = Pandas::Series.new(data)
      vector = Charty::Vector.new(series)
      assert do
        not vector.categorical?
      end
    end

    data(
      "for string array"                   => ["abc", "def", "xyz"],
      "for string array with nil at head"  => [nil, "abc", "xyz"],
    )
    def test_categorical_with_categorical(data)
      series = Pandas::Series.new(data).astype("category")
      vector = Charty::Vector.new(series)
      assert do
        vector.categorical?
      end
    end
  end

  sub_test_case("#categories") do
    data(
      "for numeric array"                  => [1, 2, 3, 4, 5],
      "for string array"                   => ["abc", "def", "xyz"],
      "for numeric array with nil at head" => [nil, 1, 2, 3],
      "for string array with nil at head"  => [nil, "abc", "xyz"]
    )
    def test_categories_with_noncategorical(data)
      series = Pandas::Series.new(data)
      vector = Charty::Vector.new(series)
      assert_nil(vector.categories)
    end

    data(
      "for string array"                   => ["abc", "def", "xyz"],
      "for string array with nil at head"  => [nil, "abc", "xyz"]
    )
    def test_categories_with_categorical(data)
      series = Pandas::Series.new(data).astype("category")
      vector = Charty::Vector.new(series)
      assert_equal(data.compact,
                   vector.categories)
    end
  end

  sub_test_case("#unique_values") do
    def setup
      super
      @data = [3, 1, 3, 2, 1]
      @series = Pandas::Series.new(@data)
      @vector = Charty::Vector.new(@series)
    end

    def test_unique_values
      result = @vector.unique_values
      assert_equal({
                     class: Array,
                     values: @data.uniq
                   },
                   {
                     class: result.class,
                     values: result
                   })
    end
  end

  sub_test_case("#group_by") do
    test("when grouper is also a Charty::Vector of a Pandas::Series") do
      vector = Charty::Vector.new(Pandas::Series.new([1, 2, 3, 4, 5]))
      grouper = Charty::Vector.new(Pandas::Series.new(["a", "b", "a", "a", "b"]))
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Pandas::Series, "b" => Pandas::Series },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is a Charty::Vector but not of a Pandas::Series") do
      vector = Charty::Vector.new(Pandas::Series.new([1, 2, 3, 4, 5]))
      grouper = Charty::Vector.new(["a", "b", "a", "a", "b"])
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Pandas::Series, "b" => Pandas::Series },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is a Pandas::Series") do
      vector = Charty::Vector.new(Pandas::Series.new([1, 2, 3, 4, 5]))
      grouper = Pandas::Series.new(["a", "b", "a", "a", "b"])
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Pandas::Series, "b" => Pandas::Series },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end

    test("when grouper is an Array") do
      vector = Charty::Vector.new(Pandas::Series.new([1, 2, 3, 4, 5]))
      grouper = ["a", "b", "a", "a", "b"]
      result = vector.group_by(grouper)
      assert_equal({
                     classes:      { "a" => Charty::Vector, "b" => Charty::Vector },
                     data_classes: { "a" => Pandas::Series, "b" => Pandas::Series },
                     data:         { "a" => [1, 3, 4]     , "b" => [2, 5] }
                   },
                   {
                     classes:      { "a" => result["a"].class     , "b" => result["b"].class },
                     data_classes: { "a" => result["a"].data.class, "b" => result["b"].data.class },
                     data:         { "a" => result["a"].data.to_a , "b" => result["b"].data.to_a }
                   })
    end
  end

  data(
    "for numeric array without NA"  => { array: [1, 2, 3, 4, 5]           , expected: [1, 2, 3, 4, 5] },
    "for string array without NA"   => { array: ["abc", "def", "xyz"]     , expected: ["abc", "def", "xyz"] },
    "for numeric array with NAs"    => { array: [nil, 1, 2, Float::NAN, 3], expected: [1, 2, 3] },
    "for string array with NAs"     => { array: [nil, "abc", nil, "xyz"]  , expected: ["abc", "xyz"] },
  )
  def test_drop_na(data)
    array, expected = data.values_at(:array, :expected)
    series = Pandas::Series.new(array)
    vector = Charty::Vector.new(series)
    result = vector.drop_na
    assert_equal({
                   class: Charty::Vector,
                   data_class: Pandas::Series,
                   values: expected
                 },
                 {
                   class: result.class,
                   data_class: result.data.class,
                   values: result.data.to_a
                 })
  end
end
