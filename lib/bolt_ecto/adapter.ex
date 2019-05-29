defmodule Bolt.Ecto.Adapter do
  alias Bolt.Sips, as: BoltSips

  require Logger

  defmacro __before_compile__(_opts), do: :ok

  # Adapter callbacks
  def ensure_all_started(_repo, type), do: Application.ensure_all_started(:bolt_ecto, type)

  def init(opts) do
    {:ok, Supervisor.Spec.worker(BoltSips, [opts]), %{}}
  end

  def checkout(_meta, _opts, _fun), do: nil

  def autogenerate(:id), do: nil
  def autogenerate(:embed_id), do: Ecto.UUID.generate()
  def autogenerate(:binary_id), do: Ecto.UUID.bingenerate()

  @doc false
  def loaders(:uuid, Ecto.UUID), do: [&{:ok, &1}]
  def loaders(:naive_datetime, _type), do: [&NaiveDateTime.from_iso8601(&1)]
  def loaders(_primitive, type), do: [type]

  def dumpers(:uuid, Ecto.UUID), do: [&{:ok, &1}]

  def dumpers(:naive_datetime, type) when type in [:naive_datetime, NaiveDateTime] do
    [
      fn
        %NaiveDateTime{} = dt -> {:ok, NaiveDateTime.to_iso8601(dt)}
      end
    ]
  end

  def dumpers(_primitive, type), do: [type]

  # READ
  def prepare(cmd, query) do
    cypher = apply(Bolt.Ecto.Query, cmd, [query])
    {:nocache, {cypher, query}}
  end

  def execute(_repo, _query_meta, {:nocache, {cypher, query}}, params, _process) do
    BoltSips.query(BoltSips.conn(), cypher, query_params(params))
    |> process_result(fn val -> mapper(val, query) end)
  end

  def stream(_repo, _query_meta, {:nocache, {cypher, query}}, params, _process) do
    BoltSips.query(BoltSips.conn(), cypher, query_params(params))
    |> process_result(fn val -> mapper(val, query) end)
  end

  defp process_result({:ok, %{stats: _stats}}, _mapper), do: :ok

  defp process_result({:ok, result}, mapper), do: decode_map(result, mapper)

  defp process_result({:error, err}, _mapper), do: raise_error(err)

  # WRITE
  def insert(_repo, schema_meta, fields, _on_conflict, _returning, _options) do
    # Build cypher params from fields and metadata
    cypher_params = Enum.into(fields, %{}) |> replace_uuid(fields, schema_meta) |> params_parser

    # IO.inspect(Enum.into(fields, %{}))
    # IO.inspect(cypher_params)

    cypher =
      "CREATE (n:#{schema_meta.source} { #{fields_parser(cypher_params)} }) RETURN #{
        return_fields(fields)
      }"

    # IO.inspect(cypher)

    BoltSips.query(BoltSips.conn(), cypher, cypher_params)
    |> process_insert_result()
  end

  def insert_all(_repo, _schema_meta, _header, _list, _on_conflict, _returning, _options) do
    raise "Not supported"
  end

  def update(_repo, schema_meta, fields, filters, _returning, _options) do
    # Build cypher params from fields and metadata
    cypher_filters =
      Enum.into(filters, %{}) |> replace_uuid(filters, schema_meta) |> params_parser

    cypher_params = Map.merge(Enum.into(fields, %{}) |> params_parser, cypher_filters)

    where = where_fields(cypher_filters)
    set = set_fields(cypher_params)

    cypher = "MATCH (n:#{schema_meta.source}) #{where} #{set} RETURN count(*) as count"

    # IO.inspect(cypher)
    # IO.inspect(cypher_params)

    BoltSips.query(BoltSips.conn(), cypher, cypher_params)
    |> process_insert_result()
  end

  def delete(_repo, schema_meta, fields, _options) do
    # Build cypher params from fields and metadata
    cypher_params = Enum.into(fields, %{}) |> replace_uuid(fields, schema_meta) |> params_parser

    cypher = "MATCH (n:#{schema_meta.source} { #{fields_parser(cypher_params)} }) DETACH DELETE n"

    # IO.inspect(cypher)
    # IO.inspect(cypher_params)

    BoltSips.query(BoltSips.conn(), cypher, cypher_params)
    |> process_insert_result()
  end

  def remap_insert_return(result) do
    result
    |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)
    |> Enum.into(%{})
  end

  defp process_insert_result({:ok, _result}) do
    {:ok, []}
  end

  defp process_insert_result({:error, err}), do: raise_error(err)

  # Helper
  def replace_uuid(params, fields, schema_meta) do
    if(schema_meta.autogenerate_id == nil) do
      params
    else
      # Get uuid field
      {id_field, _type, _binary_id} = schema_meta.autogenerate_id

      # Decode uuid
      {:ok, uuid} = Ecto.UUID.load(fields[id_field])

      # Merge into params
      Map.merge(params, %{id: uuid})
    end
  end

  defp params_parser(params) do
    params
    |> Enum.filter(fn {_k, v} -> v && v != "" end)
    |> Enum.map(fn {k, v} -> {k, encode_value(v)} end)
    |> Enum.into(%{})
  end

  def fields_parser(fields) do
    fields
    |> Enum.filter(fn {_k, v} -> v && v != "" end)
    |> Enum.map(fn {k, _v} -> "#{Atom.to_string(k)} : $#{Atom.to_string(k)}" end)
    |> Enum.join(", ")
  end

  def return_fields(fields) do
    fields
    |> Enum.filter(fn {_k, v} -> v && v != "" end)
    |> Enum.map(fn {k, _v} -> "n.#{k} as #{k}" end)
    |> Enum.join(", ")
  end

  def where_fields(fields, node_alias \\ "n") do
    where =
      fields
      |> Enum.filter(fn {_k, v} -> v && v != "" end)
      |> Enum.map(fn {k, _v} -> "#{node_alias}.#{Atom.to_string(k)} = $#{Atom.to_string(k)}" end)
      |> Enum.join(" AND ")

    "WHERE #{where}"
  end

  def set_fields(fields, node_alias \\ "n") do
    set =
      fields
      |> Enum.filter(fn {_k, v} -> v && v != "" end)
      |> Enum.map(fn {k, _v} -> "#{node_alias}.#{Atom.to_string(k)} = $#{Atom.to_string(k)}" end)
      |> Enum.join(", ")

    "SET #{set}"
  end

  def encode_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  def encode_value(v) when is_map(v) do
    Poison.encode!(v)
  end

  def encode_value(v), do: v

  defp query_params(params) do
    params
    |> Enum.with_index(1)
    |> Enum.map(fn {k, v} -> {"p#{v}", k} end)
    |> Map.new()
  end

  defp decode_map(data, nil), do: {:erlang.length(data), data}

  defp decode_map(data, mapper) do
    {cnt, list} = decode_map(data, mapper, {0, []})
    {cnt, :lists.reverse(list)}
  end

  defp decode_map([row | data], mapper, {cnt, decoded}),
    do: decode_map(data, mapper, {cnt + 1, [mapper.(row) | decoded]})

  defp decode_map([], _, decoded), do: decoded
  
  defp decode_map(nil, _, decoded), do: decoded

  defp mapper(row, query) do
    cols = result_columns(query)
    result = clean_result(row)
    Enum.map(cols, fn k -> result[k] end)
  end

  defp clean_result(data) do
    Enum.map(data, fn {key, val} -> {extract_column_name(key), val} end)
    |> Enum.into([])
  end

  defp result_columns(query) do
    query.select.fields |> Enum.map(fn expr -> extract_column_key(expr) end)
  end

  def extract_column_key(expr) when expr != nil do
    {{_, _, [_head | columns]}, _type, _} = expr
    hd(columns)
  end

  def extract_column_key(expr), do: expr

  defp extract_column_name(field) do
    split_field = String.split(field, ".")
    Enum.at(split_field, length(split_field) - 1) |> String.to_atom()
  end

  defp raise_error(code: _code, message: message) do
    raise message
  end
end
