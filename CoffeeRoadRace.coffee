jQuery ($) ->

    class CoffeeRoadRace

        constructor: (@canvasId) ->
            @canvas = document.getElementById @canvasId
            @ctx = @canvas.getContext "2d"

            @width = @canvas.width
            @halfWidth = @width/2
            @height = @canvas.height

            # Depth of the visible road
            @roadLines = (0.5 + @height / 2)|0  #150
            @widthStep = (@height * 0.5) / @roadLines  # 1
            @zFactor = 95
            @zFactor2 = 1.2
            # Line of the player's car
            @noScaleLine = 16

            # Animation
            @speed = 5
            @texOffset = 100
            @nextStretch = "straight"
            @pause = false

            # Road Colors
            @colortheme =
                true: ["#00a030", "#f0f0f0", "#888888", "#f0f0f0"],
                false: ["#008040", "#f01060", "#666666"]
            @sideWidth = 20

            # Sharpness of the curves
            @ddx = 0.015
            @ddx *= @widthStep
            @segmentY = @roadLines
            # Hills, Slopes
            @ddy = 0.01
            @ddy *= @widthStep

            @populateZMap()


        # Populate the zMap with the depth of the road lines
        populateZMap: ->
            @zMap = []
            for i in [0...@roadLines]
                @zMap.push 1.0 / (i*@widthStep - @height / 2.0)

            playerZ = 100.0 / @zMap[@noScaleLine]
            for i in [0...@roadLines]
                @zMap[i] *= playerZ


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
                            #dy -= @ddy
                        else
                            dx -= @ddx / 64
                            #dy += @ddy

                    when "curved"
                        if i <= @segmentY
                            dx += @ddx
                            #dy -= @ddy
                        else
                            dx -= @ddx / 64
                            #dy += @ddy
                rx += dx
                ry += dy - 1

            half_width = @halfWidth - (@widthStep * @roadLines)
            j = 0
            y = 0
            scanlines = []
            for i in [0...@roadLines]
                j = @roadLines - 1 - i
                road_texture = (@zMap[j] + @texOffset) % 100 > 50
                y = (0.5 + rry[j])|0
                scanlines[y] = [road_texture, (0.5 + rrx[j])|0, y, half_width / @zFactor - @zFactor2, i]
                half_width += @widthStep

            h = y = y2 = 0
            len = scanlines.length
            while y < len
                if scanlines[y]
                    h = 1
                    y2 = y + 1
                    while y2 < len and (!scanlines[y2] or scanlines[y2][4] < scanlines[y][4])
                        ++h
                        ++y2
                    if h > 1 && scanlines[y2]
                        @drawRoadLine2 scanlines[y][0], scanlines[y][1], scanlines[y2][1], scanlines[y][2], scanlines[y2][2], scanlines[y][3], scanlines[y2][3], h
                    else
                        @drawRoadLine scanlines[y][0], scanlines[y][1], scanlines[y][2], scanlines[y][3], h
                    y += h
                else
                    ++y

            delete scanlines
            return


        drawRoadLine2: (texture, x, x2, y, y2, scaleX, scaleX2, h) ->
            @ctx.fillStyle = @colortheme[texture][0]
            @ctx.fillRect 0, y, @width, h

            side = @halfWidth / 2
            side *= scaleX
            side_width = @sideWidth
            side_width *= scaleX
            # convert to integer
            side = (0.5 + side)|0
            side_width = (0.5 + side_width)|0

            side2 = @halfWidth / 2
            side2 *= scaleX2
            side_width2 = @sideWidth
            side_width2 *= scaleX2
            # convert to integer
            side2 = (0.5 + side2)|0
            side_width2 = (0.5 + side_width2)|0

            @ctx.fillStyle = @colortheme[texture][1]

            # left road side
            @ctx.beginPath()
            @ctx.moveTo x - side - side_width, y
            @ctx.lineTo x - side, y
            @ctx.lineTo x2 - side2, y2
            @ctx.lineTo x2 - side2 - side_width2, y2
            @ctx.closePath()
            @ctx.fill()

            # right road side
            @ctx.beginPath()
            @ctx.moveTo x + side, y
            @ctx.lineTo x + side + side_width, y
            @ctx.lineTo x2 + side2 + side_width2, y2
            @ctx.lineTo x2 + side2, y2
            @ctx.closePath()
            @ctx.fill()

            # road
            @ctx.fillStyle = @colortheme[texture][2]
            @ctx.beginPath()
            @ctx.moveTo x - side, y
            @ctx.lineTo x - side + side * 2, y
            @ctx.lineTo x2 - side2 + side2 * 2, y2
            @ctx.lineTo x2 - side2, y2
            @ctx.closePath()
            @ctx.fill()

            # middle of the road
            if texture
                half_side_width = (0.5 + side_width / 2)|0
                half_side_width2 = (0.5 + side_width2 / 2)|0

                @ctx.fillStyle = @colortheme[texture][3]
                @ctx.beginPath()
                @ctx.moveTo x - half_side_width, y
                @ctx.lineTo x - half_side_width + side_width, y
                @ctx.lineTo x2 - half_side_width2 + side_width2, y2
                @ctx.lineTo x2 - half_side_width2, y2
                @ctx.closePath()
                @ctx.fill()

            return

        drawRoadLine: (texture, x, y, scaleX, h = 1) ->
            @ctx.fillStyle = @colortheme[texture][0]
            @ctx.fillRect 0, y, @width, h

            side = @halfWidth / 2
            side_width = @sideWidth
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

