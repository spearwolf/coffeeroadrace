class RoadModel

    constructor: (width, height) ->
        @renderQueue = []
        @worker = new Worker 'RoadModel.js'
        @worker.postMessage
            action: 'init',
            width: width,
            height: height
        self = this
        @worker.addEventListener 'message', (e) ->
            if e.data.action is 'renderList'
                self.renderQueue.push e.data.renderList

    createRenderList: (xOffset, texOffset) ->
        @worker.postMessage
            action: 'createRenderList',
            xOffset: xOffset,
            texOffset: texOffset
        @renderQueue.shift()


window.RoadModel = RoadModel
