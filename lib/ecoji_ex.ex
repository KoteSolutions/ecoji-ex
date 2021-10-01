defmodule EcojiEx do
  use Bitwise, only_operators: true
  use EcojiEx.Runes

  def encode(x) do
    encode(x, "")
  end

  defp encode("", result) do
    result
  end

  defp encode(x, result) do
    {new_x, tmp_result} =
      case x do
        <<a::binary-size(5), rest::binary>> ->
          <<a1, a2, a3, a4, a5>> = a

          tail =
            @pos2rune[a1 <<< 2 ||| a2 >>> 6] <>
              @pos2rune[(a2 &&& 0x3F) <<< 4 ||| a3 >>> 4] <>
              @pos2rune[(a3 &&& 0x0F) <<< 6 ||| a4 >>> 2] <>
              @pos2rune[(a4 &&& 0x03) <<< 8 ||| a5]

          {rest, result <> tail}

        <<a::binary-size(4), rest::binary>> ->
          <<a1, a2, a3, a4>> = a

          tail =
            @pos2rune[a1 <<< 2 ||| a2 >>> 6] <>
              @pos2rune[(a2 &&& 0x3F) <<< 4 ||| a3 >>> 4] <>
              @pos2rune[(a3 &&& 0x0F) <<< 6 ||| a4 >>> 2]

          last =
            case a4 &&& 0x03 do
              0 -> @pad40
              1 -> @pad41
              2 -> @pad42
              3 -> @pad43
            end

          {rest, result <> tail <> last}

        <<a::binary-size(3), rest::binary>> ->
          <<a1, a2, a3>> = a
          a4 = 0

          tail =
            @pos2rune[a1 <<< 2 ||| a2 >>> 6] <>
              @pos2rune[(a2 &&& 0x3F) <<< 4 ||| a3 >>> 4] <>
              @pos2rune[(a3 &&& 0x0F) <<< 6 ||| a4 >>> 2] <>
              @pad

          {rest, result <> tail}

        <<a::binary-size(2), rest::binary>> ->
          <<a1, a2>> = a
          a3 = 0

          tail =
            @pos2rune[a1 <<< 2 ||| a2 >>> 6] <>
              @pos2rune[(a2 &&& 0x3F) <<< 4 ||| a3 >>> 4] <>
              @pad <>
              @pad

          {rest, result <> tail}

        <<a::binary-size(1), rest::binary>> ->
          <<a1>> = a
          a2 = 0

          tail =
            @pos2rune[a1 <<< 2 ||| a2 >>> 6] <>
              @pad <>
              @pad <>
              @pad

          {rest, result <> tail}
      end

    encode(new_x, tmp_result)
  end

  def decode(x) do
    decode(x, "")
  end

  defp decode("", result) do
    result
  end

  defp decode(x, result) do
    {[gr1, gr2, gr3, gr4], rest} = take_graphemes(x, 4)

    b1 = @rune2pos[gr1] || 0
    b2 = @rune2pos[gr2] || 0
    b3 = @rune2pos[gr3] || 0

    b4 =
      case gr4 do
        @pad40 -> 0
        @pad41 -> 1 <<< 8
        @pad42 -> 2 <<< 8
        @pad43 -> 3 <<< 8
        _ -> @rune2pos[gr4] || 0
      end

    out = <<
      b1 >>> 2,
      (b1 &&& 0x3) <<< 6 ||| b2 >>> 4,
      (b2 &&& 0xF) <<< 4 ||| b3 >>> 6,
      (b3 &&& 0x3F) <<< 2 ||| b4 >>> 8,
      b4 &&& 0xFF
    >>

    size =
      cond do
        gr2 == @pad -> 1
        gr3 == @pad -> 2
        gr4 == @pad -> 3
        gr4 in [@pad40, @pad41, @pad42, @pad43] -> 4
      end

    out = binary_part(out, 0, size)

    decode(rest, <<result::binary, out::binary>>)
  end

  def all_runes do
    @all_runes
  end

  defp take_graphemes(bin, num) do
    take_graphemes(bin, num, [])
  end

  defp take_graphemes(bin, 0, acc) do
    {Enum.reverse(acc), bin}
  end

  defp take_graphemes("", num, acc) do
    take_graphemes("", num - 1, [nil | acc])
  end

  defp take_graphemes(bin, num, acc) do
    {gr, rest} = String.next_grapheme(bin)
    take_graphemes(rest, num - 1, [gr | acc])
  end
end
