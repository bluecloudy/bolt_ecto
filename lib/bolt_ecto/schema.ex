defmodule Bolt.Ecto.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      type =
        Application.get_env(:ecto, :primary_key_type) ||
          raise ":primary_key_type not set in :ecto application"

      @primary_key {:id, type, autogenerate: true}
      @foreign_key_type type
    end
  end
end
