require! xml2js
require! fs
require! iconv.Iconv
iconv = new Iconv "CP1250" "UTF-8"
(err, body) <~ fs.readFile "#__dirname/../data/CIS5575_CS.xml"
body = iconv.convert body .toString!
(err, data) <~ xml2js.parseString body
polozky =  data.EXPORT.DATA.0.POLOZKA.map ->
  [it.CHODNOTA.0, it.TEXT.0].join "\t"
polozky.unshift "kod\tnazev"
fs.writeFile "#__dirname/../data/ciselnik.tsv" polozky.join "\n"
