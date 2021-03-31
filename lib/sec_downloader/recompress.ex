defmodule SecDownloader.Recompress do
  def run() do
    fnames =
      File.ls!("filings")
      |> Enum.filter(fn fname -> not String.contains?(fname, ".gz") end)

    SecDownloader.Counter.start_link([])

    fnames
    |> Flow.from_enumerable()
    |> Flow.map(fn fname ->
      f = File.read!("filings/#{fname}")
      File.write!("filings/#{fname}.gz", f, [:compressed])
      File.rm!("filings/#{fname}")
      SecDownloader.Counter.inc()
    end)
    |> Flow.run()
  end
end
