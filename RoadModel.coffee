class RoadModel

    constructor: (@width, @height) ->
        @roadLines = (0.5 + @height / 2)|0
        @halfWidth = @width/2
        @heightStep = (@height * 0.5) / @roadLines
        @zFactor = @height >> 1
        @zFactor2 = 1.95
        @zFactor3 = 2.0
        @noScaleLine = 8
        @populateZMap()
        @ddx = 0.015 * @heightStep
        @ddy = 0.01 * @heightStep

    populateZMap: ->
        # Populate the zMap with the depth of the road lines
        @zMap = (1.0 / ((i * @heightStep) - (@height / 1.85)) for i in [0...@roadLines])
        playerZ = 100.0 / @zMap[@noScaleLine]
        for i in [0...@roadLines]
            @zMap[i] *= playerZ
        return

    updateRoad: (xOffset, texOffset) ->  # {{{
        rx = @halfWidth + xOffset
        ry = @height - 1
        rrx = []
        rry = []
        dx = dy = 0
        for i in [0...@roadLines]
            rrx.push rx
            rry.push ry

            #switch @nextStretch
                #when "straight"
                    #if i >= @segmentY
                        #dx += @ddx
                        #dy -= @ddy
                    #else
                        #dx -= @ddx / 64
                        #dy += @ddy

                #when "curved"
                    #if i <= @segmentY
                        #dx += @ddx
                        #dy -= @ddy
                    #else
                        #dx -= @ddx / 64
                        #dy += @ddy
            rx += dx
            ry += dy - 1

        distance = @height - (@heightStep * @roadLines)
        j = y = scaleX = 0
        scan = []
        for i in [0...@roadLines]
            j = @roadLines - 1 - i
            tex = (@zMap[j] + texOffset) % 100 > 50
            y = (rry[j])|0
            scaleX = ((distance * @zFactor3) / @zFactor) - @zFactor2
            scan[y] = [tex, rrx[j], y, scaleX, i]
            distance += @heightStep

        h = y = y2 = 0
        len = scan.length
        backgroundPosition = null
        renderList = []
        while y < len
            if scan[y]
                unless backgroundPosition
                    backgroundPosition = [scan[y][1], scan[y][2]]
                    renderList.push [0, backgroundPosition[0], backgroundPosition[1]]
                h = 1
                y2 = y + 1
                while y2 < len and (!scan[y2] or scan[y2][4] < scan[y][4])
                    ++h
                    ++y2
                renderList.push [1, scan[y][0], scan[y][2], h]
                if h > 1 && scan[y2]
                    renderList.push [3, scan[y][0], scan[y][1], scan[y2][1], scan[y][2], scan[y2][2], scan[y][3], scan[y2][3], h]
                else
                    renderList.push [2, scan[y][0], scan[y][1], scan[y][2], scan[y][3], h]
                y += h
            else
                ++y

        delete scan
        return renderList


roadModel = null
self.addEventListener "message", (e) ->
    switch e.data.action
        when 'init'
            roadModel = new RoadModel e.data.width, e.data.height
        when 'updateRoad'
            self.postMessage
                action: 'renderList',
                renderList: roadModel.updateRoad(e.data.xOffset, e.data.texOffset)

