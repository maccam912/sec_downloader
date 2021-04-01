defmodule SecDownloader.Recompress do
  def run() do
    fnames =
      File.ls!("filings")
      |> Enum.filter(fn fname -> not String.contains?(fname, ".gz") end)

    SecDownloader.Counter.start_link(length(fnames))

    fnames
    |> Flow.from_enumerable(stages: 16*4, min_demand: 16*4, max_demand: 16*8)
    |> Flow.map(fn fname ->
      f = File.read!("filings/#{fname}")
      File.write!("filings/#{fname}.gz", f, [:compressed])
      File.rm!("filings/#{fname}")
      SecDownloader.Counter.inc()
    end)
    |> Flow.run()
  end
end
