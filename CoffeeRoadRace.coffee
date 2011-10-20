jQuery ($) ->

    class CoffeeRoadRace

        constructor: (@canvasId) ->
            @canvas = document.getElementById @canvasId
            @ctx = @canvas.getContext "2d"

            @width = @canvas.width
            @halfWidth = @width/2
            @height = @canvas.height

            # Depth of the visible road
            @roadLines = 155
            @widthStep = 1
            # Line of the player's car
            @noScaleLine = 8

            # Animation
            @speed = 5
            @texOffset = 100
            @nextStretch = "straight"
            @pause = false

            # Road Colors
            @colortheme =
                true: ["#00a030", "#f0f0f0", "#888888", "#f0f0f0"],
                false: ["#008040", "#f01060", "#666666"]

            # Steering
            @ddx = 0.02  # Sharpness of the curves
            @segmentY = @roadLines
            # Hills, Slopes
            @ddy = 0.01

            @populateZMap()


        # Populate the zMap with the depth of the road lines
        populateZMap: ->
            @zMap = []
            for i in [0...@roadLines]
                @zMap.push 1.0 / (i - @height / 2.0)

            playerZ = 100.0 / @zMap[@noScaleLine]
            for i in [0...@roadLines]
                @zMap[i] *= playerZ

            console.log @zMap


        drawRoad: ->
            @clearCanvas()

            rx = @halfWidth
            ry = @height - 1
            rrx = []
            rry = []
            dx = dy = 0
            for i in [0...@roadLines]
                rrx.push rx
                rry.push ry

                switch @nextStretch
                    when "straight"
                        if i >= @segmentY
                            dx += @ddx
                            dy -= @ddy
                        else
                            dx -= @ddx / 64
                            dy += @ddy

                    when "curved"
                        if i <= @segmentY
                            dx += @ddx
                            dy -= @ddy
                        else
                            dx -= @ddx / 64
                            dy += @ddy
                rx += dx
                ry += dy - 1

            half_width = @halfWidth - (@widthStep * @roadLines)
            j = 0
            for i in [0...@roadLines]
                # TODO Implement a scanline algorithm here!!
                j = @roadLines - 1 - i
                road_texture = (@zMap[j] + @texOffset) % 100 > 50
                @drawRoadLine road_texture, rrx[j], rry[j], half_width / 60 - 1.2
                half_width += @widthStep
            return


        drawRoadLine: (texture, x, y, scaleX = 1.0, h = 42) ->
            x = (0.5 + x)|0
            y = (0.5 + y)|0
            @ctx.fillStyle = @colortheme[texture][0]
            @ctx.fillRect 0, y, @width, h

            side = @halfWidth / 2
            side_width = 20
            side *= scaleX
            side_width *= scaleX
            side = (0.5 + side)|0
            side_width = (0.5 + side_width)|0

            @ctx.fillStyle = @colortheme[texture][1]
            @ctx.fillRect x - side - side_width, y, side_width, h
            @ctx.fillRect x + side, y, side_width, h

            @ctx.fillStyle = @colortheme[texture][2]
            @ctx.fillRect x - side, y, side * 2, h

            if texture
                @ctx.fillStyle = @colortheme[texture][3]
                @ctx.fillRect (0.5 + x - side_width/2)|0, y, side_width, h
            return


        clearCanvas: ->
            @ctx.fillStyle = "#60a0c0"
            @ctx.fillRect 0, 0, @width, @height
            return


        race: ->
            return if @pause

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

