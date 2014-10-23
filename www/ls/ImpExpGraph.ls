window.ig.ImpExpGraph = class ImpExpGraph
  (@parentElement, @ciselnik) ->
    window.ig.Events @
    width = 1000px
    height = 700px
    @margin = [10 0 30 60]
    @height = height - @margin.0 - @margin.2
    @width = width - @margin.1 - @margin.3
    @lastDomains = []
    @lastActiveLayer = []
    @lastLayerAssoc = []
    @lastLayers = []
    @lastKody = []
    @currentLayers = null
    @svg = @parentElement.append \svg
      ..attr \class \impExpGraph
      ..attr \width width
      ..attr \height height
    @drawing = @svg.append \g
      ..attr \class \drawing
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
    baseDuration = 0
    if targetArea
      area = d3.svg.area!
        ..x ~> @xScale it.date
        ..y0 (it, i) ~> @yScale it.y0 + targetArea.layerPoints[i].y0
        ..y1 (it, i) ~> @yScale it.y + it.y0 + targetArea.layerPoints[i].y0
      @currentAreas
        ..transition!
          ..duration 800
          ..attr \d ~> area it.layerPoints
        ..transition!
          ..delay 1600
          ..remove!
      baseDuration = 1200
    else
      baseDuration = 0
      @currentAreas.remove!
    fadingKod = @lastKody.pop!toString!
    @currentKod = @lastKody[*-1]
    @drawCurrentArea @lastLayers.pop!
      ..attr \opacity 0
      ..transition!
        ..delay (d, i) -> baseDuration + i * 50
        ..duration 600
        ..attr \opacity 1
        ..attr \class \drawed
      ..filter (.kod == fadingKod)
        ..transition!
          ..delay 800
          ..duration 800
          ..attr \opacity 1
    @lastLayerAssoc.pop!
    @emit 'drawing' @currentKod

  goTo: (kod) ->
    @currentAreas.remove!
    @drawSubset kod

  drawSubset: (kod) ->
    @emit \focusing kod
    @lastKody.push kod
    @currentKod = kod
    tempPath = @expand kod
    @lastLayers.push @currentLayers
    drawSubset = ~>
      layers = @stackData data
      if not tempPath
        max = d3.max layers[*-1].layerPoints.map -> it.y0 + it.y
        @yScale.domain [0, max]
        @yAxisG.call @yAxis
      lastAreas = @currentAreas
      @highlightOff!
      currentArea = @drawCurrentArea layers
        ..attr \fill-opacity 0
        ..attr \stroke-opacity 0
        ..attr \stroke-width 1
        ..attr \stroke \black
        ..transition!
          ..delay (d, i) -> i * 50
          ..duration 400
          ..attr \stroke-opacity 1
        ..transition!
          ..delay (d, i) -> 200 + i * 100
          ..duration 600
          ..attr \stroke-opacity 0
          ..attr \stroke-width 0
          ..attr \fill-opacity 1
      @emit 'drawing' kod
      <~ setTimeout _, 800 + layers.length * 100
      currentArea.attr \class \drawed
      if tempPath
        tempPath.remove!
    startImmediately = no
    data = null
    if tempPath
      setTimeout do
        -> if data then drawSubset! else startImmediately = yes
        1600
    else
      startImmediately = yes

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
      ..attr \class \drawed

  drawCurrentArea: (layers) ->
    @currentLayers = layers
    @currentAreas = @drawing.selectAll \path.new .data layers .enter!append \path
      ..attr \d ~> @stdAreaGenerator it.layerPoints
      ..attr \class "highlighted"
      ..attr \fill ~>
        @color it.kod
      ..attr \opacity 1
      ..on \click ~> @drawSubset it.kod
      ..on \mouseover ~> @highlight it.kod
      ..on \mouseout ~> @highlightOff!
      ..on \mousemove ~>
        x = d3.event.x - @margin.3
        date = @xScale.invert x
        @emit \pointer date

  highlight: (kod) ->
    kod .= toString!
    @emit \highlight kod
    @currentAreas.classed \highlight off
    @drawing.classed \highlighted on
    @currentAreas
      .filter (.kod == kod)
      .classed \highlight on

  highlightOff: ->
    @emit \highlight null
    @drawing.classed \highlighted off

  stackData: (data) ->
    layers_assoc = {}
    @lastLayerAssoc.push layers_assoc
    for {kod}:datum in data
      layers_assoc[kod] ?= []
      layers_assoc[kod].push datum
    layers = for kod, layerPoints of layers_assoc
      layerPoints = extrapolate layerPoints, @dateRange
      {kod, layerPoints}

    @stack layers
    layers

  expand: (kod) ->
    layer = @lastLayerAssoc[*-1][kod]
    @lastDomains.push @yScale.domain!
    return unless layer
    max = d3.max layer.map -> it.y
    @yScale.domain [0, max]
    @yAxisG
      ..transition!
        ..delay 600
        ..duration 800
        ..call @yAxis
    area = d3.svg.area!
      ..x ~> @xScale it.date
      ..y0 ~> @yScale 0
      ..y1 ~> @yScale it.y
    fadingAreaElm = @currentAreas.filter -> it.kod == kod.toString!
    @currentAreas
      ..transition!
        ..duration 600
        ..attr \opacity 0
        ..remove!
    @lastActiveLayer.push fadingAreaElm.datum!
    @tempPath = @drawing.append \path
      ..attr \d fadingAreaElm.attr \d
      ..attr \class "highlight"
      ..attr \fill fadingAreaElm.attr \fill
      ..datum fadingAreaElm.datum!
      ..transition!
        ..delay 600
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
  lastInput = null
  rangeLength = range.length
  out = range.map (rangeItem, index) ->
    if input[currentIndex]?obdobi == rangeItem.obdobi
      lastInput := input[currentIndex]
      ++currentIndex
      input[currentIndex - 1]
    else if lastInput and (rangeLength - index) < 5
      date         : rangeItem.date
      obdobi       : rangeItem.obdobi
      cena         : lastInput.cena
      lastInput    : lastInput
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
