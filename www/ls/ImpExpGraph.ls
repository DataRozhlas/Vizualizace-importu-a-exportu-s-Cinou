window.ig.ImpExpGraph = class ImpExpGraph
  (@parentElement, @ciselnik) ->
    width = 1000px
    height = 700px
    @margin = [10 0 30 60]
    @height = height - @margin.0 - @margin.2
    @width = width - @margin.1 - @margin.3
    @lastDomains = []
    @lastActiveLayer = []
    @lastLayers = []
    @lastKody = []
    @currentLayers = null
    @svg = @parentElement.append \svg
      ..attr \class \impExpGraph
      ..attr \width width
      ..attr \height height
    @drawing = @svg.append \g
      ..attr \transform "translate(#{@margin.3}, #{@margin.0})"
    @setXScale!
    @drawXAxis!
    @prepareYScale!
    @prepareYAxis!
    @stack = d3.layout.stack!
      ..values (.layerPoints)
      ..x (.date)
      ..y (.cena)
    @color = d3.scale.ordinal!
      ..range ['rgb(228,26,28)','rgb(55,126,184)','rgb(77,175,74)','rgb(152,78,163)','rgb(255,127,0)','rgb(255,255,51)','rgb(166,86,40)','rgb(247,129,191)'] ++ ['rgb(141,211,199)','rgb(255,255,179)','rgb(190,186,218)','rgb(251,128,114)','rgb(128,177,211)','rgb(253,180,98)','rgb(179,222,105)','rgb(252,205,229)']

  drawImport: ->
    data = d3.tsv.parse ig.data.import, tsvTransform
    @direction = 'import'
    @draw data

  drawExport: ->
    data = d3.tsv.parse ig.data.export, tsvTransform
    @direction = 'export'
    @draw data

  back: ->
    d = @lastDomains.pop!
    @yScale.domain d
    targetArea = @lastActiveLayer.pop!
    area = d3.svg.area!
      ..x ~> @xScale it.date
      ..y0 (it, i) ~> @yScale it.y0 + targetArea.layerPoints[i].y0
      ..y1 (it, i) ~> @yScale it.y + it.y0 + targetArea.layerPoints[i].y0
    @currentAreas.transition!
      ..duration 800
      ..attr \d ~> area it.layerPoints
    currentKod = @lastKody.pop!toString!
    @drawCurrentArea @lastLayers.pop!
      ..attr \opacity 0
      ..transition!
        ..delay (d, i) -> 1200 + i * 50
        ..duration 600
        ..attr \opacity 1
      ..filter (.kod == currentKod)
        ..transition!
          ..delay 800
          ..duration 800
          ..attr \opacity 1

  drawSubset: (kod) ->
    @lastKody.push kod
    @expand kod
    drawSubset = ~>
      layers = @stackData data
      lastAreas = @currentAreas
      @drawCurrentArea layers
        ..attr \fill-opacity 0
        ..attr \stroke-opacity 0
        ..attr \stroke-width 1
        ..attr \stroke \black
        ..transition!
          ..delay (d, i) -> i * 50
          ..duration 400
          ..attr \stroke-opacity 1
        ..transition!
          ..delay (d, i) -> 400 + i * 100
          ..duration 800
          ..attr \stroke-opacity 0
          ..attr \stroke-width 0
          ..attr \fill-opacity 1
      <~ setTimeout _, 1200 + layers.length * 100
      @tempPath.remove!
    startImmediately = no
    data = null
    setTimeout do
      -> if data then drawSubset! else startImmediately = yes
      1600

    (err, d) <~ d3.tsv "../data/#{@direction}/#{kod}.tsv", tsvTransform
    data := d
    if startImmediately then drawSubset!

  draw: (data) ->
    data.sort (a, b) -> a.time - b.time
    @dateRange = generateDateRange data.0, data[*-1]
    layers = @stackData data
    max = d3.max layers[*-1].layerPoints.map -> it.y0 + it.y
    @yScale.domain [0, max]
    @yAxisG.call @yAxis
    @stdAreaGenerator = d3.svg.area!
      ..x ~> @xScale it.date
      ..y0 ~> @yScale it.y0
      ..y1 ~> @yScale it.y0 + it.y
    @drawCurrentArea layers

  drawCurrentArea: (layers) ->
    @lastLayers.push @currentLayers if @currentLayers
    @currentLayers = layers
    @currentAreas = @drawing.selectAll \path.new .data layers .enter!append \path
      ..attr \d ~> @stdAreaGenerator it.layerPoints
      ..attr \fill ~>
        @color it.kod
      ..attr \data-tooltip ~> @ciselnik[it.kod]
      ..attr \opacity 1
      ..on \click ~> @drawSubset it.kod

  stackData: (data) ->
    @displayedLayersAssoc = layers_assoc = {}
    for {kod}:datum in data
      layers_assoc[kod] ?= []
      layers_assoc[kod].push datum
    layers = for kod, layerPoints of layers_assoc
      layerPoints = extrapolate layerPoints, @dateRange
      {kod, layerPoints}

    @stack layers
    layers

  expand: (kod) ->
    layer = @displayedLayersAssoc[kod]
    return unless layer
    max = d3.max layer.map -> it.y
    @lastDomains.push @yScale.domain!
    @yScale.domain [0, max]
    @yAxisG
      ..transition!
        ..delay 800
        ..duration 800
        ..call @yAxis
    area = d3.svg.area!
      ..x ~> @xScale it.date
      ..y0 ~> @yScale 0
      ..y1 ~> @yScale it.y
    fadingAreaElm = @currentAreas.filter -> it.kod == kod.toString!
    @currentAreas
      ..transition!
        ..duration 800
        ..attr \opacity 0
        ..remove!
    @lastActiveLayer.push fadingAreaElm.datum!
    @tempPath = @drawing.append \path
      ..attr \d fadingAreaElm.attr \d
      ..attr \fill fadingAreaElm.attr \fill
      ..datum fadingAreaElm.datum!
      ..transition!
        ..delay 800
        ..duration 800
        ..attr \d -> area it.layerPoints


  drawXAxis: ->
    @xAxis = d3.svg.axis!
      ..scale @xScale
      ..tickSize 5, 1

    @xAxisG = @svg.append \g
      ..attr \class "axis x"
      ..attr \transform "translate(#{@margin.3}, #{@margin.0 + @height})"
      ..call @xAxis

  setXScale: ->
    @startDate = new Date!
      ..setTime 0
      ..setMonth 0
      ..setFullYear 1999
    @endDate = new Date!
      ..setTime 0
      ..setMonth 9
      ..setFullYear 2014
    @xScale = d3.time.scale!
      ..domain [@startDate, @endDate]
      ..range [0, @width]

  prepareYScale: ->
    @yScale = d3.scale.linear!
      ..range [@height, 0]

  prepareYAxis: ->
    @yAxis = d3.svg.axis!
      ..scale @yScale
      ..orient "left"
      ..tickSize 5, 1
      ..tickFormat ->
        | it == 0 => "0 Kč"
        | it < 1e3 => it + " tis."
        | it < 1e6 => it / 1e3 + " mil."
        | otherwise => it / 1e6 + " mld."

    @yAxisG = @svg.append \g
      ..attr \class "axis y"
      ..attr \transform "translate(#{@margin.3}, #{@margin.0})"

class RangeItem
  (date) ->
    @date = new Date!
      ..setTime date.getTime!
    obdobiMesic = (@date.getMonth! + 1).toString!
    if obdobiMesic.length == 1
      obdobiMesic = "0" + obdobiMesic
    @obdobi = "#{obdobiMesic}/#{@date.getFullYear!}"
    @cena = 0
    @extrapolated = yes


generateDateRange = (min, max) ->
  currentDate = new Date!
    ..setTime 0
    ..setMonth min.date.getMonth!
    ..setFullYear min.date.getFullYear!
  currentMonth =  currentDate.getMonth!
  currentYear = currentDate.getFullYear!
  i = 0
  out = []
  while currentDate.getTime! <= max.time
    out.push new RangeItem currentDate
    currentMonth += 1
    if currentMonth > 11
      currentMonth = 0
      currentYear += 1
      currentDate.setFullYear currentYear
    currentDate.setMonth currentMonth
  out.push new RangeItem currentDate
  out


smooth = (input) ->
  accu = []
  avg = ->
    sum = 0
    for val in accu
      sum += val
    sum / accu.length
  input
    .filter (.extrapolated != yes)
    .forEach (item, index) ->
      accu.push item.cena
      if index >= 3 then accu.shift!
      item.cena = avg!
  input


extrapolate = (input, range) ->
  currentIndex = 0
  lastCena = null
  rangeLength = range.length
  out = range.map (rangeItem, index) ->
    if input[currentIndex]?obdobi == rangeItem.obdobi
      lastCena := input[currentIndex].cena
      ++currentIndex
      input[currentIndex - 1]
    else if lastCena and (rangeLength - index) < 5
      date         : rangeItem.date
      obdobi       : rangeItem.obdobi
      cena         : lastCena
      extrapolated : yes
    else
      rangeItem
  out


tsvTransform = (row) ->
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
