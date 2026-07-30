{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "npmvet";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "harksys";
    repo = "npmvet";
    rev = "802a968d365b6ae22a8332e0287a35097ab2e7eb";
    hash = "sha256-aIxpYP1c5SerNvs0V6LkZudrES781YRrl6XOGVidURc=";
  };

  npmDepsHash = "sha256-FQVv8n5Pd+A21Mp5nHWJRSeXRJ2CT+J5foa9tunULm4=";

  # TypeScript sources need to be compiled to dist/
  npmBuildScript = "build";

  meta = {
    description = "A simple CLI tool for vetting npm package versions";
    homepage = "https://github.com/harksys/npmvet";
    license = lib.licenses.mit;
    mainProgram = "npmvet";
  };
}
