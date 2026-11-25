// Adapted from nyanshiba/harness-bonsai (MIT), commit 6e32b7673495966de274a2fb5fb7bd7defc92e8e.
// See LICENSE.harness-bonsai.
import { statSync } from "node:fs"
import { homedir } from "node:os"
import { resolve } from "node:path"

function resolveTarget(base, raw) {
  let target = raw.replace(/^\/move\s+/, "").trim()
  if (
    (target.startsWith('"') && target.endsWith('"')) ||
    (target.startsWith("'") && target.endsWith("'"))
  ) {
    target = target.slice(1, -1).trim()
  }
  if (!target) throw new Error("Usage: /move <directory>")
  if (target === "~") return homedir()
  if (target.startsWith("~/")) return resolve(homedir(), target.slice(2))
  return resolve(base, target)
}

function isDirectory(path) {
  try {
    return statSync(path).isDirectory()
  } catch {
    return false
  }
}

function sleep(ms) {
  return new Promise((done) => setTimeout(done, ms))
}

export default {
  id: "session-move",
  async setup(ctx) {
    await ctx.command.transform((editor) => {
      editor.add({
        name: "move",
        description: "Move session to another directory",
        execute: async ({ sessionID, prompt }) => {
          const directory = resolveTarget(ctx.location.directory, prompt.text)
          if (!isDirectory(directory)) throw new Error(`Not a directory: ${directory}`)
          await ctx.session.move({ sessionID, directory })
          await ctx.session.synthetic({ sessionID, text: `Moved to ${directory}` })
          for (let i = 0; i < 8; i++) {
            await sleep(250)
            try {
              const current = await ctx.session.get({ sessionID })
              if (current.location.directory === directory) break
            } catch {
              break
            }
          }
          try {
            await ctx.session.interrupt({ sessionID, continue: false })
          } catch {
          }
        },
      })
    })
  },
}
