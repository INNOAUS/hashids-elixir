ExUnit.start()

defmodule HashidsTest.Helpers do
  defmacro testcase_from_fixture(name) do
    testcase_from_fixture("base", name)
  end

  defmacro testcase_from_fixture_large(name) do
    testcase_from_fixture("large", name)
  end

  defp testcase_from_fixture(basepath, name) do
    {options, tests} =
      File.read!(Path.join([__DIR__, "fixtures", "v1.0.0", basepath, name]))
      |> parse_test_case()

    quote do
      test unquote(name) do
        s = Hashids.new(unquote(options))
        for {nums, encoded} <- unquote(tests) do
          assert encoded == Hashids.encode(s, nums)
          assert List.wrap(nums) === Hashids.decode(s, encoded)
        end
      end
    end
  end

  def tests_from_fixture_large(path) do
    File.read!(Path.join([__DIR__, "fixtures", "v1.0.0", "large", path]))
    |> tests_from_string()
  end

  def tests_from_fixture(path) do
    File.read!(Path.join([__DIR__, "fixtures", "v1.0.0", "base", path]))
    |> tests_from_string()
  end

  @header_re ~r/#\s+salt:\s+'([^']*)'\s+min_len:\s+(\d+)\s+alphabet:\s+(?:'([^']+)'|(<default>))$/

  defp parse_test_case(str) do
    [header, rest] = String.split(str, "\n", parts: 2)
    options = case Regex.run(@header_re, header) do
      [_, salt, min_len, alphabet, _] -> build_opts(salt, min_len, alphabet)
      [_, salt, min_len, alphabet]    -> build_opts(salt, min_len, alphabet)
    end
    tests = tests_from_string(rest)
    {options, tests}
  end

  defp build_opts(salt, min_len, alphabet) do
    salt = String.to_char_list(salt)
    len = String.to_integer(min_len)
    alphabet_opt = if alphabet == "", do: [], else: [alphabet: String.to_char_list(alphabet)]
    alphabet_opt ++ [salt: salt, min_len: len]
  end

  defp tests_from_string(str) do
    str
    |> String.split("\n")
    |> Enum.map(&String.strip/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&match?("#"<>_, &1))
    |> Enum.map(&split_fields/1)
  end

  defp split_fields(str) do
    # [1 2 3 4] <encoded>
    case Regex.run(~r/^\[([\d ]+)\]\s+(.+)$/, str) do
      [_, numstr, encoded] ->
        numbers =
          numstr
          |> String.split(" ")
          |> Enum.map(&String.strip/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.to_integer/1)
        {numbers, String.to_char_list(encoded)}

      _ ->
        # <number> <encoded>
        [numstr, encoded] = String.split(str, " ")
        {String.to_integer(numstr), String.to_char_list(encoded)}
    end
  end
end
