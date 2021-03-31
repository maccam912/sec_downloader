defmodule SecDownloader.Recompress do
  def run() do
    File.ls!("filings")
    |> Enum.map(fn fname ->
      f = File.read!("filings/#{fname}")
      File.write!("filings/#{fname}.gz", f, [:compressed])
      File.rm!("filings/#{fname}")
    end)
    |> Enum.run()
  end
end
