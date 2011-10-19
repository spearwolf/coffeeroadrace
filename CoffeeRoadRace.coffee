jQuery ($) ->

    class CoffeeRoadRace
        constructor: (@id) ->
            @roadCanvas = document.getElementById @id
            @width = @roadCanvas.width
            @halfWidth = @width/2
            @height = @roadCanvas.height
            @ctx = @roadCanvas.getContext "2d"

            @roadLines = 155  # Depth of the visible road
            @widthStep = 1
            @noScaleLine = 8  # Line of the player's car

            # Populate the zMap with the depth of the road lines
            @zMap = []
            for i in [0...@roadLines]
                @zMap.push 1.0 / (i - @height / 2.0)

            playerZ = 100.0 / @zMap[@noScaleLine]
            for i in [0...@roadLines]
                @zMap[i] *= playerZ

            # Animation
            @speed = 5
            @texOffset = 100

            # Colors
            @colortheme =
                true: ["#00a030", "#f0f0f0", "#888888", "#f0f0f0"],
                false: ["#008040", "#f01060", "#666666"]

            # Steering
            @ddx = 0.02  # Sharpness of the curves
            @segmentY = @roadLines
            @nextStretch = "straight"

            @clearCanvas()

        clearCanvas: ->
            @ctx.fillStyle = "#60a0c0"
            @ctx.fillRect 0, 0, @width, @height

        drawRoad: ->
            half_width = @halfWidth - (@widthStep * @roadLines)

            rx = @halfWidth
            dx = 0
            rrx = []
            for i in [0...@roadLines]
                switch @nextStretch
                    when "straight"
                        if i >= @segmentY
                            dx += @ddx
                        else
                            dx -= @ddx / 64

                    when "curved"
                        if i <= @segmentY
                            dx += @ddx
                        else
                            dx -= @ddx / 64
                rx += dx  # XXX reverse(i) / pre-calc
                rrx.push rx

            for i in [0...@roadLines]
                y = @height - @roadLines + i
                road_texture = (@zMap[@roadLines - 1 - i] + @texOffset) % 100 > 50

                @drawRoadLine road_texture, rrx[@roadLines-1-i], y, half_width / 60 - 1.2
                half_width += @widthStep


        drawRoadLine: (texture, x, y, scaleX = 1.0, h = 10) ->
            @ctx.fillStyle = @colortheme[texture][0]
            @ctx.fillRect 0, y, @width, h

            side = @halfWidth / 2
            side_width = 20
            side *= scaleX
            side_width *= scaleX

            @ctx.fillStyle = @colortheme[texture][1]
            @ctx.fillRect x - side - side_width, y, side_width, h
            @ctx.fillRect x + side, y, side_width, h

            @ctx.fillStyle = @colortheme[texture][2]
            @ctx.fillRect x - side, y, side * 2, h

            if texture
                @ctx.fillStyle = @colortheme[texture][3]
                @ctx.fillRect x - side_width/2, y, side_width, h


        race: ->
            @texOffset += @speed
            if @texOffset >= 100
                @texOffset -= 100

            @segmentY -= 1
            if @segmentY < 0
                @segmentY += @roadLines
                if @nextStretch == 'straight'
                    @nextStretch = "curved"
                else
                    @nextStretch = 'straight'

            @drawRoad()


    # http://active.tutsplus.com/tutorials/games/create-a-racing-game-without-a-3d-engine/
    #
    console.log("CoffeeRoadRace by spearwolf <wolfger@spearwolf.de>")

    racer = window.racer = new CoffeeRoadRace "roadRaceCanvas"

    reqAnimFrame = window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame
    anim = ->
        racer.race()
        reqAnimFrame anim

    anim()

