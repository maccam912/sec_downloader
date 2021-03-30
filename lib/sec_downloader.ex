defmodule SecDownloader do
  NimbleCSV.define(IndexParser, separator: "|", escape: "\"")

  def get_index(url) do
    {st, %HTTPoison.Response{body: body}} = HTTPoison.get(url, [], [recv_timeout: 60000])

    if st != :ok do
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

  def get_urls() do
    get_quarters()
    |> Flow.from_enumerable(stages: 4, min_demand: 10, max_demand: 20)
    |> Flow.map(fn {year, qtr} ->
      get_index_url(year, qtr)
    end)
    |> Flow.flat_map(fn url ->
      get_index(url)
      |> Flow.from_enumerable()
      |> Flow.map(fn item ->
        Map.get(item, :filename)
      end)
    end)
    |> Flow.map(fn filename ->
      [_, _, _, adsh_txt] = String.split(filename, ["/"])
      {adsh_txt, "https://www.sec.gov/Archives/#{filename}"}
    end)
    |> Flow.map(fn {adsh_txt, url} ->
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(url, [], [recv_timeout: 60000])
      IO.puts "Saving #{adsh_txt}"
      IO.inspect File.write("filings/#{adsh_txt}", body)
    end)
    |> Flow.filter(fn st -> st != :ok end)
    |> Enum.to_list()
  end

  def get_index_url(year, qtr) do
    "https://www.sec.gov/Archives/edgar/full-index/#{year}/#{qtr}/xbrl.idx"
  end

  def get_quarters() do
    2021..2021
    |> Enum.flat_map(fn year ->
      [{year, "QTR1"}, {year, "QTR2"}, {year, "QTR3"}, {year, "QTR4"}]
    end)
  end
end
