window.ig.Header = class Header
  (@baseElement, @impExpGraph, @ciselnik) ->
    @element = @baseElement.append \div
      ..attr \class \header
    @heading = @element.append \h1
    @impExpGraph.on \drawing @~update
    @backbutton = window.ig.utils.backbutton @element
      ..on \click @impExpGraph~back
    @update!

  update: ->
    if @impExpGraph.currentKod
      @backbutton.classed \disabled no
      @heading.html @ciselnik[@impExpGraph.currentKod]
    else
      @backbutton.classed \disabled yes
      verb = if @impExpGraph.direction == "import" then "dovážíme z" else "vyvážíme do"
      @heading.html "Co všechno #verb Číny"




