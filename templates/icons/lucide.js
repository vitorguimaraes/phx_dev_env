const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = plugin(function({matchComponents, theme}) {
  let iconsDir = path.join(__dirname, "../../deps/lucide/icons")
  let values = {}
  fs.readdirSync(iconsDir).filter(file => file.endsWith(".svg")).forEach(file => {
    let name = path.basename(file, ".svg")
    values[name] = {name, fullPath: path.join(iconsDir, file)}
  })
  matchComponents({
    "lucide": ({name, fullPath}) => {
      let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
      // Lucide SVGs have a fixed 24px size; remove it (only from the root <svg> tag,
      // inner shapes like <rect> need their own width/height) so the icon scales with the element
      content = content.replace(/<svg\b[^>]*>/, tag => tag.replace(/\s(width|height)="\d+"/g, ""))
      content = encodeURIComponent(content)
      let size = theme("spacing.6")
      return {
        [`--lucide-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
        "-webkit-mask": `var(--lucide-${name})`,
        "mask": `var(--lucide-${name})`,
        "mask-repeat": "no-repeat",
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "mask-position": "center",
        "background-color": "currentColor",
        "vertical-align": "middle",
        "display": "inline-block",
        "width": size,
        "height": size
      }
    }
  }, {values})
})
