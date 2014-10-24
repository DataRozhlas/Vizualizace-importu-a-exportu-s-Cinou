ig = window.ig

init = ->
  ciselnik = {}
  ciselnik_arr = []
  for line in ig.data.ciselnik.split "\n"
    [kod, nazev] = line.split "\t"
    continue if kod == "kod"
    ciselnik[kod] = nazev
    nazevSearchable = nazev.toLowerCase!stripDiacritics!
    ciselnik_arr.push {kod, nazev, nazevSearchable}
  new Tooltip!watchElements!
  container = d3.select ig.containers.base
  impExpGraph = new ig.ImpExpGraph container, ciselnik
  if -1 != window.location.hash.indexOf 'export'
    impExpGraph.drawExport!
  else
    impExpGraph.drawImport!
  header = new ig.Header container, impExpGraph, ciselnik
  sugCont = container.append \div
    ..attr \class \suggester-container
  sugCont
    ..append \b
      ..html "Vyhledat"

  suggester = new ig.Suggester sugCont, ciselnik_arr
    ..on \selected ->
      impExpGraph.goTo it.kod
  if window.location.hash && window.location.hash != '#export'
    impExpGraph.goTo do
      window.location.hash.replace do
        /[#a-z]+/
        ''
  sugCont.append \i
      ..html "Zkuste třeba zelenina, vánoční ozdoby nebo&nbsp;telefonní&nbsp;přístroje"

if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
