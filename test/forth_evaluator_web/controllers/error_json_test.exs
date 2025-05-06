defmodule ForthEvaluatorWeb.ErrorJSONTest do
  use ForthEvaluatorWeb.ConnCase, async: true

  test "renders 404" do
    assert ForthEvaluatorWeb.ErrorJSON.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert ForthEvaluatorWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
