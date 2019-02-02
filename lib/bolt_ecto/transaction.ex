defmodule Bolt.Ecto.Transaction do
  alias Bolt.Sips, as: Bolt

  @doc false
  def transaction(adapter_meta, opts, callback) do
    checkout_or_transaction(:transaction, adapter_meta, opts, callback)
  end

  @doc false
  def in_transaction?(%{pid: pool}) do
    match?(%DBConnection{conn_mode: :transaction}, get_conn(pool))
  end

  @doc false
  def rollback(%{pid: pool}, value) do
    case get_conn(pool) do
      %DBConnection{conn_mode: :transaction} = conn -> Bolt.rollback(conn, value)
      _ -> raise "cannot call rollback outside of transaction"
    end
  end

  defp checkout_or_transaction(fun, adapter_meta, opts, callback) do
    %{pid: pool} = adapter_meta

    callback = fn conn ->
      previous_conn = put_conn(pool, conn)

      try do
        callback.()
      after
        reset_conn(pool, previous_conn)
      end
    end

    apply(Bolt, fun, [get_conn_or_pool(pool), callback, opts])
  end

  defp get_conn_or_pool(_pool) do
    Bolt.conn()
  end

  defp get_conn(pool) do
    Process.get(key(pool))
  end

  defp put_conn(pool, conn) do
    Process.put(key(pool), conn)
  end

  defp reset_conn(pool, conn) do
    if conn do
      put_conn(pool, conn)
    else
      Process.delete(key(pool))
    end
  end

  defp key(pool), do: {__MODULE__, pool}
end
