defmodule Bolt.Ecto do
  @moduledoc false

  @behaviour Ecto.Adapter

  # Delegates for Adapter behaviour

  defmacro __before_compile__(_env) do
  end

  defdelegate ensure_all_started(repo, type), to: Bolt.Ecto.Adapter
  defdelegate init(opts), to: Bolt.Ecto.Adapter
  defdelegate checkout(meta, opts, fun), to: Bolt.Ecto.Adapter

  defdelegate autogenerate(field_type), to: Bolt.Ecto.Adapter
  defdelegate dumpers(primitive_type, ecto_type), to: Bolt.Ecto.Adapter
  defdelegate loaders(primitive_type, ecto_type), to: Bolt.Ecto.Adapter

  @behaviour Ecto.Adapter.Schema
  @behaviour Ecto.Adapter.Queryable

  defdelegate delete(repo, schema_meta, filters, options), to: Bolt.Ecto.Adapter

  defdelegate execute(repo, query_meta, query, params, process),
    to: Bolt.Ecto.Adapter

  defdelegate stream(repo, query_meta, query, params, process),
    to: Bolt.Ecto.Adapter

  defdelegate prepare(cmd, query),
    to: Bolt.Ecto.Adapter

  defdelegate insert(repo, schema_meta, fields, on_conflict, returning, options),
    to: Bolt.Ecto.Adapter

  defdelegate insert_all(repo, schema_meta, header, list, on_conflict, returning, options),
    to: Bolt.Ecto.Adapter

  defdelegate update(repo, schema_meta, fields, filters, returning, options),
    to: Bolt.Ecto.Adapter

  @behaviour Ecto.Adapter.Transaction

  defdelegate transaction(meta, opts, fun),
    to: Bolt.Ecto.Transaction

  defdelegate in_transaction?(meta),
    to: Bolt.Ecto.Transaction

  defdelegate rollback(name, value),
    to: Bolt.Ecto.Transaction

  @behaviour Ecto.Adapter.Migration

  # Delegates for Migration behaviour

  defdelegate supports_ddl_transaction?, to: Bolt.Ecto.Migration
  defdelegate execute_ddl(repo, ddl, opts), to: Bolt.Ecto.Migration
  defdelegate lock_for_migrations(meta, query, opts, callback), to: Bolt.Ecto.Migration
end
