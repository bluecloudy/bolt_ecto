defmodule Ecto.Integration.User do
  use Ecto.Schema

  schema "User" do
    field(:username, :string)
    field(:language, :string)
  end
end
