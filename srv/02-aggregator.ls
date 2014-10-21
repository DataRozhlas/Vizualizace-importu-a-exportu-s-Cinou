# ke spusteni pro import a export - switchnutelne pres promennou expImp

require! fs
require! async

expImp = "import"
outDir = "#__dirname/../data/#expImp"
codeLen = 4
lines = fs.readFileSync "#__dirname/../data/#expImp.tsv" .toString!split "\n"
  ..shift!
# lines.length = 100
aggregateFor = (prefix, cb) ->
  summ = {}
  prefixLength = prefix.length
  something = no
  for line in lines
    line .= replace "\r" ""
    [obdobi, id, nazev, cena] = line.split "\t"
    continue unless id
    continue unless prefix is id.substr 0, prefixLength
    something = yes
    aggr = id.substr 0, prefixLength + 1
    summId = aggr + "-" + obdobi
    cena = parseInt cena, 10
    summ[summId] ?= 0
    summ[summId] += cena
  if not something
    if cb
      process.nextTick cb
    return
  out = "obdobi\tkod\tcena"
  for summId, cena of summ
    [aggr, obdobi] = summId.split "-"
    out += "\n#obdobi\t#aggr\t#cena"

  if prefix == ''
    prefix = 'all'
  <~ fs.writeFile "#outDir/#prefix.tsv", out
  if cb
    process.nextTick cb
aggregateFor ''
(err, ciselnik) <~ fs.readFile "#__dirname/../data/ciselnik.tsv"
ciselnikLines = ciselnik.toString!split "\n"
  ..shift!

kody = for line in ciselnikLines
  [kod] = line.split "\t"
  continue if kod.length >= 5
  kod
i = 0
# kody.length = 5
len = kody.length
async.eachLimit kody, 5, (kod, cb) ->
  i++
  if 0 == i % 10
    console.log "3i / #len (#{(i / len * 100).toFixed 2} %) "
  aggregateFor kod, cb
