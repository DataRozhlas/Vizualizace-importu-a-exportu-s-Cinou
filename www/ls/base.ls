ig = window.ig
ig.tsvTransform = (row) ->
  row.cena = parseInt row.cena, 10
  [month, year] = row.obdobi.split "/"
  month = parseInt month, 10
  year = parseInt year, 10
  row.date = new Date!
    ..setTime 0
    ..setMonth month - 1
    ..setFullYear year
  row.time = row.date.getTime!
  row

init = ->
  exp = d3.tsv.parse ig.data.export, ig.tsvTransform
  new ig.ImpExpGraph d3.select ig.containers.base
    ..draw exp
if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
