defmodule SecDownloader.Recompress do
  def run() do
    fnames = File.ls!("filings")
    |> Enum.filter(fn fname -> not String.contains?(fname, ".gz") end)

    fnames
    |> Stream.map(fn fname ->
      f = File.read!("filings/#{fname}")
      File.write!("filings/#{fname}.gz", f, [:compressed])
      File.rm!("filings/#{fname}")
    end)
    |> Tqdm.tqdm(total: length(fnames))
    |> Stream.run()
  end
end
