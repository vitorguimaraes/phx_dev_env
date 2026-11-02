# Credo's default files plus dev/ (the screen prototypes); the default checks apply
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "test/", "web/", "apps/*/lib/", "apps/*/src/", "apps/*/test/", "apps/*/web/", "dev/"],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      }
    }
  ]
}
