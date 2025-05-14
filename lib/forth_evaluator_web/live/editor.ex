defmodule ForthEvaluatorWeb.Live.Editor do
  use ForthEvaluatorWeb, :live_view

  alias ForthEvaluator.Repo
  alias ForthEvaluator.Program

  import Ecto.Query, only: [from: 2]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       current_program: %Program{text: "", output: ""},
       program_history: get_program_history()
     )}
  end

  def handle_event("submit-program", %{"program-text" => text}, socket) do
    program =
      socket.assigns[:current_program]
      |> Program.changeset(%{text: text, status: "RUNNING"})
      |> Repo.insert_or_update!()

    socket =
      socket
      |> assign(:current_program, program)
      |> update_program_history()

    start_evaluation(program)

    {:noreply, socket}
  end

  def handle_event("new-program", _params, socket) do
    {:noreply, assign(socket, :current_program, %Program{text: "", output: ""})}
  end

  def handle_event("load-program", %{"id" => id}, socket) do
    program = Repo.get!(Program, id)
    {:noreply, assign(socket, :current_program, program)}
  end

  def handle_info({:evaluation_done, program}, socket) do
    current_program? = program.id == socket.assigns[:current_program].id

    # If the program that finished evaluating is the current one,
    # update its changes in the view.
    socket =
      if current_program?,
        do: assign(socket, :current_program, program),
        else: socket

    {:noreply, update_program_history(socket)}
  end

  defp get_program_history() do
    query = from(prog in Program, order_by: [desc: prog.last_update])
    Repo.all(query)
  end

  defp update_program_history(socket) do
    assign(socket, :program_history, get_program_history())
  end

  defp start_evaluation(program) do
    connection_process = self()

    Task.Supervisor.start_child(ForthEvaluator.EvalSupervisor, fn ->
      {:ok, stack} = ForthEvaluator.Stack.start_link()
      {:ok, dictionary} = ForthEvaluator.Dictionary.start_link()

      update = Program.run(program, stack, dictionary) |> Map.from_struct()
      changeset = Program.changeset(program, %{update | status: "DONE"})
      updated = Repo.update!(changeset)

      send(connection_process, {:evaluation_done, updated})
    end)
  end
end
