ExUnit.start()

Application.put_env(:ecto, :primary_key_type, :binary_id)
Application.put_env(:ecto, :async_integration_tests, false)

Code.require_file("../deps/ecto_sql/integration_test/support/repo.exs", __DIR__)

Code.require_file("./support/schemas.exs", __DIR__)

defmodule Ecto.Integration.TestRepo do
  use Ecto.Integration.Repo, otp_app: :ecto, adapter: Bolt.Ecto

  # def all(queryable, opts \\ []) do
  #   Ecto.Repo.Queryable.all(__MODULE__, queryable, opts)
  # end

  # def one(queryable, opts \\ []) do
  #   Ecto.Repo.Queryable.one(__MODULE__, queryable, opts)
  # end

  # def get(queryable, id, opts \\ []) do
  #   Ecto.Repo.Queryable.get(__MODULE__, queryable, id, opts)
  # end

  # def get_by(queryable, clauses, opts \\ []) do
  #   Ecto.Repo.Queryable.get_by(__MODULE__, queryable, clauses, opts)
  # end

  # def insert(struct, opts \\ []) do
  #   Ecto.Repo.Schema.insert(__MODULE__, struct, opts)
  # end
end

# Basic test repo
alias Ecto.Integration.TestRepo

Application.put_env(
  :ecto,
  TestRepo,
  hostname: "neo4j",
  basic_auth: [
    username: "neo4j",
    password: "admin"
  ],
  port: 7687,
  pool_size: 5,
  max_overflow: 1
)

defmodule Ecto.Integration.Case do
  use ExUnit.CaseTemplate

  # alias Ecto.Integration.TestRepo

  setup_all do
    :ok
  end

  setup do
    :ok
  end
end

# _ = Bolt.Ecto.storage_down(TestRepo.config())
# :ok = Bolt.Ecto.storage_up(TestRepo.config())

{:ok, _pid} = TestRepo.start_link()
# :ok = TestRepo.stop(pid, :infinity)
# {:ok, _pid} = TestRepo.start_link()

# # We capture_io, because of warnings on references
# ExUnit.CaptureIO.capture_io(fn ->
#   :ok = Ecto.Migrator.up(TestRepo, 0, Ecto.Integration.Migration, log: false)
# end)
