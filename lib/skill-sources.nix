{ inputs }:

inputs.agent-skills.lib.agent-skills.sourcesFromLock {
  manifestsDir = ../registry/sources;
  lockFile = ../registry/sources.lock.json;
}
