defmodule ForthEvaluatorWeb.Live.Editor do
  use ForthEvaluatorWeb, :live_view

  alias ForthEvaluator.Repo
  alias ForthEvaluator.Program

  import Ecto.Query, only: [from: 2]

  def mount(_params, _session, socket) do
    default_program = %{text: "", output: ""}

    {:ok,
     assign(socket, current_program: default_program, program_history: get_program_history())}
  end

  def handle_event("submit-program", %{"program-text" => text}, socket) do
    socket = update(socket, :current_program, fn program -> %{program | text: text} end)
    changeset = Program.changeset(%Program{status: "RUNNING"}, socket.assigns[:current_program])
    Repo.insert!(changeset)

    send(self(), "update_history")

    {:noreply, push_event(socket, "update_history", %{})}
  end

  def handle_info("update_history", socket) do
    {:noreply, assign(socket, :program_history, get_program_history())}
  end

  defp get_program_history() do
    query = from(prog in Program, order_by: [desc: prog.last_update])
    Repo.all(query)
  end
end
