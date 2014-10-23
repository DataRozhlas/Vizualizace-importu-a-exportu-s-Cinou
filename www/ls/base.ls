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
    ..drawImport!
  header = new ig.Header container, impExpGraph, ciselnik
  sugCont = container.append \div
    ..attr \class \suggester-container
  sugCont
    ..append \b
      ..html "Vyhledat"

  suggester = new ig.Suggester sugCont, ciselnik_arr
    ..on \item -> impExpGraph.goTo it.kod
  if window.location.hash
    impExpGraph.goTo that.replace '#' ''
  sugCont.append \i
      ..html "Zkuste třeba drůbež, tříkolky nebo paruky"

if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
