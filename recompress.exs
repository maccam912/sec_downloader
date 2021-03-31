defmodule SecDownloader.Recompress do
  def run() do
    File.ls!("filings")
    |> Flow.from_enumerable()
    |> Flow.map(fn filename ->
      f = File.read!("filings/#{fname}")
      File.write!("filings/#{fname}.gz", f, [:compressed])
      File.rm!("filings/#{fname}")
    end)
    |> Flow.run()
  end
end
