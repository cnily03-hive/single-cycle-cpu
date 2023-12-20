const fs = require('fs')
const path = require('path')

const filepath = process.argv[2]

if (!filepath) {
    console.log('Please provide a file path')
    process.exit(1)
}

if (fs.existsSync(filepath) === false) {
    console.log('File not found: ' + filepath)
    process.exit(1)
}

if (fs.statSync(filepath).isDirectory()) {
    console.log(`'${filepath}' is a directory`)
    process.exit(1)
}

const file_dir = path.dirname(path.resolve(process.cwd(), filepath))
const filename = path.basename(filepath, path.extname(filepath))
const output_filename = `${filename}.hex`
const output_filepath = path.resolve(file_dir, output_filename)

const bin_content = fs.readFileSync(filepath, 'utf8')

const hex_content = bin_content
    .replace(/ /g, '')
    .split('\n')
    .map(t => Number("0b" + t).toString(16).toUpperCase().padStart(8, "0"))
    .join('\n')

fs.writeFileSync(output_filepath, hex_content, 'utf8')

console.log(`File created at '${output_filepath}'`)
