defmodule HtmlToImage do
  @moduledoc """
  Provides a wrapper around `wkhtmltoimage` for creating images from HTML using WebKit engine
  """

  @doc """
  Converts given HTML string into binary image
  """
  def convert(html) do
    convert(html, [])
  end

  @doc """
  Converts given HTML string into binary image.

  Returns binary data <iodata> of the generated image

  ## Options

      wkhtmltoimage_path - specify a path where wkhtmltoimage tool is installed
      format - the format of output image file. Default is JPG
  """
  def convert(html, options) do
    executable = Keyword.get(options, :wkhtmltoimage_path) || executable_path
    template_name = template_file(html)
    arguments = [
      "--format", Keyword.get(options, :format) || :jpg,
      template_name,
      "-"
    ]

    result = Porcelain.exec(
      executable, arguments, [in: html, out: :iodata, err: :string]
    )

    case result.status do
      0 -> { :ok, result.out }
      _ -> { :error, result.error }
    end
  end

  defp template_file(data) do
    template = Path.join(System.tmp_dir, random_filename) <> ".jpg"
    {:ok, file} = File.open template, [:write]
    IO.binwrite file, data
    File.close file
    template
  end

  defp executable_path do
    {path, result} = System.cmd("which", ["wkhtmltoimage"])
    case result do
      0 -> path |> String.trim
      _ -> Application.get_env(:html_to_image, :wkhtmltoimage_path) || "/usr/local/bin/wkhtmltoimage"
    end
  end

  defp random_filename(length \\ 16) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

end
