defmodule Bolt.EctoTest do
  use Ecto.Integration.Case

  alias Ecto.Integration.{User}
  # alias Ecto.Integration.TestRepo

  import Ecto.Query

  defp cypher(query, operation \\ :all, counter \\ 0) do
    {query, _params, _key} = Ecto.Query.Planner.plan(query, operation, Bolt.Ecto, counter)

    {query, _} =
      query
      |> Ecto.Query.Planner.ensure_select(true)
      |> Ecto.Query.Planner.normalize(operation, Bolt.Ecto, counter)

    apply(Bolt.Ecto.Query, operation, [query])
  end

  describe "create Cypher query" do
    test "with select clause" do
      assert cypher(from(u in "User", select: u)) =~ "MATCH (U0:User) RETURN U0"
    end

    test "with select distinct" do
      assert cypher(from(u in User, select: u.username, distinct: true)) =~
               "MATCH (U0:User) RETURN DISTINCT U0.username"
    end

    test "with where clause" do
      assert cypher(from(u in User, where: u.username == "Joe", select: u.username)) =~
               "MATCH (U0:User) WHERE U0.username = 'Joe' RETURN U0.username"

      assert cypher(from(u in User, where: not (u.username == "Joe"), select: u.username)) =~
               "MATCH (U0:User) WHERE NOT U0.username = 'Joe' RETURN U0.username"

      assert cypher(from(u in User, where: like(u.username, "J"), select: u.username)) =~
               "MATCH (U0:User) WHERE U0.username CONTAINS 'J' RETURN U0.username"

      username = "Joe"

      assert cypher(from(u in User, where: u.username == ^username, select: u.username)) =~
               "MATCH (U0:User) WHERE U0.username = $p1 RETURN U0.username"

      assert cypher(from(u in User, where: u.username == "Joe" and u.language == "ru")) =~
               "MATCH (U0:User) WHERE U0.username = 'Joe' AND U0.language = 'ru' RETURN U0.id, U0.username, U0.language"

      assert cypher(from(u in User, where: u.username == "Joe" or u.language == "ru")) =~
               "MATCH (U0:User) WHERE U0.username = 'Joe' OR U0.language = 'ru' RETURN U0.id, U0.username, U0.language"
    end

    test "with 'in' operator in where clause" do
      assert cypher(from(u in User, where: u.username in [], select: u.username)) =~
               "MATCH (U0:User) WHERE FALSE RETURN U0.username"

      assert cypher(from(u in User, where: u.username in ["1", "2", "3"], select: u.username)) =~
               "MATCH (U0:User) WHERE U0.username IN ['1','2','3'] RETURN U0.username"

      assert cypher(from(u in User, where: not (u.username in []), select: u.username)) =~
               "MATCH (U0:User) WHERE NOT FALSE RETURN U0.username"
    end

    test "with 'in' operator and pinning in where clause" do
      assert cypher(from(u in User, where: u.username in ^[], select: u.username)) =~
               "MATCH (U0:User) WHERE U0.username IN $p1 RETURN U0.username"

      assert cypher(
               from(u in User, where: u.username in ["1", ^"hello", "3"], select: u.username)
             ) =~ "MATCH (U0:User) WHERE U0.username IN ['1',$p1,'3'] RETURN U0.username"

      assert cypher(from(u in User, where: u.username in ^["1", "2", "3"], select: u.username)) =~
               "MATCH (U0:User) WHERE U0.username IN $p1 RETURN U0.username"
    end

    test "with order by clause" do
      assert cypher(from(u in User, order_by: u.username, select: u.username)) =~
               "MATCH (U0:User) RETURN U0.username ORDER BY U0.username"
    end

    test "with limit and offset clauses" do
      assert cypher(from(u in User, limit: 10, select: u.username)) =~
               "MATCH (U0:User) RETURN U0.username LIMIT 10"

      assert cypher(from(u in User, limit: 10, offset: 2, select: u.username)) =~
               "MATCH (U0:User) RETURN U0.username SKIP 2 LIMIT 10"
    end
  end

  describe "create remove query" do
    test "without returning" do
      assert cypher(from(u in User, where: u.username == "Joe"), :delete_all) =~
               "MATCH (U0:User) WHERE U0.username = 'Joe' DETACH DELETE U0 RETURN U0.id, U0.username, U0.language"
    end
  end

  describe "create update query" do
    test "without returning" do
      assert cypher(
               from(u in User, where: u.username == "Joe", update: [set: [language: "en"]]),
               :update_all
             ) =~
               "MATCH (U0:User) WHERE U0.username = 'Joe' SET U0.language = 'en' RETURN U0.id, U0.username, U0.language"
    end
  end
end
