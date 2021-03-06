defmodule SecDownloader do
  use GenServer

  NimbleCSV.define(IndexParser, separator: "|", escape: "\"")

  def get_index(url) do
    IO.puts("Getting index for #{url}")
    {st, %HTTPoison.Response{body: body}} = HTTPoison.get(url, [], recv_timeout: 60000)

    IO.inspect(body)

    if st != :ok or String.length(body) < 1000 do
      [nil]
    else
      parse_task = Task.async(fn -> IndexParser.parse_string(body) end)
      {st, rows} = Task.yield(parse_task, 60000)

      if st != :ok do
        [nil]
      else
        rows
        |> Enum.filter(fn row -> length(row) == 5 end)
        |> Enum.filter(fn [cik, _, _, _, _] -> cik != "CIK" end)
        |> Enum.map(fn [cik, company_name, form_type, date_filed, filename] ->
          {cik_int, _} = Integer.parse(cik)

          %{
            cik: cik_int,
            company_name: company_name,
            form_type: form_type,
            date_filed: date_filed,
            filename: filename
          }
        end)
      end
    end
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    GenServer.cast(__MODULE__, :run)
    {:ok, []}
  end

  def handle_cast(:run, state) do
    do_work()
    {:noreply, state}
  end

  def do_work() do
    pairs =
      get_quarters()
      |> Enum.map(fn {year, qtr} ->
        IO.puts("Getting URL for #{year} #{qtr}")
        IO.inspect(get_index_url(year, qtr))
      end)
      |> Enum.flat_map(fn url ->
        get_index(url)
        |> Enum.filter(fn item -> !is_nil(item) end)
        |> Enum.map(fn item ->
          Map.get(item, :filename)
        end)
      end)
      |> Enum.filter(fn item -> !is_nil(item) end)
      |> Enum.map(fn filename ->
        [_, _, _, adsh_txt] = String.split(filename, ["/"])
        {"#{adsh_txt}.gz", "https://www.sec.gov/Archives/#{filename}"}
      end)

    IO.puts("Pairs done")
    existing = MapSet.new(File.ls!("filings"))

    pairs = Enum.filter(pairs, fn {adsh_txt, _} -> !MapSet.member?(existing, adsh_txt) end)
    pairs = Enum.shuffle(pairs)

    SecDownloader.Counter.start_link(length(pairs))

    pairs
    |> Flow.from_enumerable(stages: 4, min_demand: 10, max_demand: 20)
    |> Flow.map(fn {adsh_txt, url} ->
      :ok = SecDownloader.Counter.unlock()

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} =
        HTTPoison.get(url, [], recv_timeout: 60000)

      SecDownloader.Counter.inc()
      File.write("filings/#{adsh_txt}", body, [:compressed])
    end)
    |> Flow.filter(fn st -> st != :ok end)
    |> Enum.to_list()
  end

  def get_index_url(year, qtr) do
    "https://www.sec.gov/Archives/edgar/full-index/#{year}/#{qtr}/xbrl.idx"
  end

  def get_quarters() do
    [{2021, "QTR1"}]
    # 2021..2021
    # |> Enum.flat_map(fn year ->
    #   [{year, "QTR1"}, {year, "QTR2"}, {year, "QTR3"}, {year, "QTR4"}]
    # end)
  end
end
