{ inputs }:
{
  flake-devenv = {
    path = ./templates/flake-devenv;
    description = "Nix flake with devenv, treefmt, and git-hooks";
  };
  next-firebase-auth-e2e = {
    path = inputs.template-next-firebase-auth-e2e;
    description = "Next.js App Router with Firebase Auth and E2E testing";
  };
  web-app = {
    path = inputs.template-web-app;
    description = "Web app template by hiroppy";
  };
}
