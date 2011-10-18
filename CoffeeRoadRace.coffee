jQuery ($) ->

    class CoffeeRoadRace
        constructor: (@id) ->
            @roadCanvas = document.getElementById @id
            @width = @roadCanvas.width
            @halfWidth = @width/2
            @height = @roadCanvas.height
            @ctx = @roadCanvas.getContext "2d"

            # Depth of the visible road
            @roadLines = 155
            @widthStep = 1
            # Line of the player's car
            @noScaleLine = 8

            # Populate the zMap with the depth of the road lines
            @zMap = []
            for i in [0...@roadLines]
                @zMap.push 1.0 / (i - @height / 2.0)

            @playerZ = 100.0 / @zMap[@noScaleLine]
            for i in [0...@roadLines]
                @zMap[i] *= @playerZ

            @speed = 5
            @texOffset = 100

            @colortheme = 
                true: ["#00a030", "#f0f0f0", "#888888", "#f0f0f0"],
                false: ["#008040", "#f01060", "#666666"]

            @clearCanvas()

        clearCanvas: ->
            @ctx.fillStyle = "#60a0c0"
            @ctx.fillRect 0, 0, @width, @height

        drawRoad: ->
            half_width = @halfWidth - (@widthStep * @roadLines)
            for i in [0...@roadLines]
                y = @height - @roadLines + i
                road_texture = (@zMap[@roadLines - 1 - i] + @texOffset) % 100 > 50
                @drawRoadLine road_texture, 0, y, half_width / 60 - 1.2
                half_width += @widthStep

        drawRoadLine: (texture, x, y, scaleX = 1.0, h = 10) ->
            @ctx.fillStyle = @colortheme[texture][0]
            @ctx.fillRect 0, y, @width, h

            side = @halfWidth / 2
            side_width = 20
            side *= scaleX
            side_width *= scaleX
            @ctx.fillStyle = @colortheme[texture][1]
            @ctx.fillRect @halfWidth - side - side_width, y, side_width, h
            @ctx.fillRect @halfWidth + side, y, side_width, h

            @ctx.fillStyle = @colortheme[texture][2]
            @ctx.fillRect @halfWidth - side, y, side * 2, h

            if texture
                @ctx.fillStyle = @colortheme[texture][3]
                @ctx.fillRect @halfWidth - side_width/2, y, side_width, h


        race: ->
            @texOffset += @speed
            if @texOffset >= 100
                @texOffset -= 100
            @drawRoad()


    # http://active.tutsplus.com/tutorials/games/create-a-racing-game-without-a-3d-engine/
    #
    console.log("CoffeeRoadRace by spearwolf <wolfger@spearwolf.de>")

    window.racer = racer = new CoffeeRoadRace "roadRaceCanvas"

    reqAnim = window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame
    anim = ->
        racer.race()
        reqAnim anim

    anim()

