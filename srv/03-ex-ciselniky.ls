require! fs
files = fs.readdirSync "#__dirname/../data/import"
files .= filter -> it[*-1] != 'z'
files .= map (.split '.' .0)
console.log files.join ","
