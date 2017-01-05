defmodule Fixturist.Mixfile do
  use Mix.Project

  def project do
    [
      app: :fixturist,
      version: "0.1.0",
      elixir: "~> 1.3",
      description: description,
      package: package,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, ">= 2.0.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
     """
     Fixturist fixes the foreign-key constraints for you in your fixture driven backend tests. It is an algorithm for populating relationships from your development database
     """
  end

  defp package do
    [
      name: :fixturist,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Izel Nakri"],
      licenses: ["MIT License"],
      links: %{
        "GitHub" => "https://github.com/izelnakri/fixturist",
        "Docs" => "https://hexdocs.pm/fixturis/Fixturist.html"
      }
    ]
  end
end
