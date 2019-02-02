defmodule Bolt.Ecto.Migration do
  def execute_ddl(_repo, _ddl, _opts), do: :ok

  def supports_ddl_transaction?, do: :ok

  def lock_for_migrations(_meta, query, _opts, fun) do
    fun.(query)
  end
end
