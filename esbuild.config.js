const path = require('path');
const coffeeScriptPlugin = require('esbuild-coffeescript');

require("esbuild").context({
  entryPoints: ["application.js.coffee"],
  bundle: true,
  sourcemap: true,
  publicPath: 'assets',
  outdir: path.join(process.cwd(), "app/assets/builds"),
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  plugins: [coffeeScriptPlugin()],
  minify: process.argv.includes("--minify")
}).then(context => {
  if (process.argv.includes("--watch")) {
    // Enable watch mode
    context.watch()
  } else {
    // Build once and exit if not in watch mode
    context.rebuild().then(result => {
      context.dispose()
    })
  }
}).catch(() => process.exit(1))
