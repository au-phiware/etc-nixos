{ lib, bundlerApp, bundlerUpdateScript }:

bundlerApp {
  pname = "pact";
  gemdir = ./.;
  exes = [ "pact" "pact-broker" "pact-message" "pact-mock-service" "pact-provider-verifier" "pact-publish" "pact-stub-service" ];

  passthru.updateScript = bundlerUpdateScript "pact";

  meta = with lib; {
    description = "Fast, easy and reliable testing for integrating web apps, APIs and microservices.";
    homepage    = "https://pact.io";
    license     = licenses.mit;
    platforms   = platforms.unix;
  };
}
