defmodule EcojiExTest do
  use ExUnit.Case
  use PropCheck

  property "single encode-decode" do
    forall [i <- integer(0, :inf)] do
      ii =
        i
        |> :binary.encode_unsigned()
        |> EcojiEx.encode()
        |> EcojiEx.decode()
        |> :binary.decode_unsigned()

      i == ii
    end
  end
end
