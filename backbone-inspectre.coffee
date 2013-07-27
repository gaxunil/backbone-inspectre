App = App || {}

class App.BackboneInspectre

  constructor: (options) ->
    # hold a reference to the timer that checks our done state
    @checkTimer = null

    # hold objects that have triggered the functions we have spied on
    @queue = []

    # ingore objects with these contstructor names
    @ignoreList = []

    # list of functions to call when certain conditions are met
    @logPoints = []

    # track running state
    @running = false

    # logging
    @verbose = options?.verbose || false

    # Because we are operating on a potentially asych activity queue,
    # we look for a quiet period where no spys have been active.
    # If there is not activity after this period of time, we
    # we consider the inspecting session complete and will
    # stop running
    @doneTiming = options?.doneTiming || 1500

    # Where to log the timed events.
    # Object needs to have a function like this:
    # logTiming(category, url, timeSpent, label)
    @analyticsLogger = options.logger || null

  start: (name, url) ->
    @cleanup()
    @runName = name
    @url = url
    @running = true

  stop: ->
    @running = false

  isRunning: ->
    @running

  # add a point to log when it evaluates to true
  # we'll check it on every event we queue
  addLogPoint: (name, func) ->
    @logPoints.push {logged: false, name: name, func: func}

  log: ->
    console.log arguments if @verbose

  ignore: (constructorName) ->
    @ignoreList.push constructorName

  isIgnored: (constructorName) ->
    ret =_.contains(@ignoreList, constructorName)
    if ret
      @log "ignoring ", constructorName
    ret

  # wrap ourselves around the provided prototype function so
  # we can tap into the calls
  inspect: (proto, funcName, label)->
    mythis = this
    func = proto[funcName]
    proto[funcName] = ->
      mythis.theSpy(this, arguments, func, label)

  # the actual spy method we register
  theSpy: (that, args, func, label) ->
    if @running and not @isIgnored that.constructor.name
      @log "BEFORE ", label, that.constructor.name
      @addObject(that.collection || that.model)

    # call the oringial function
    ret = func.apply(that, args)
    if @running and not @isIgnored that.constructor.name
      @addObject(that.collection || that.model)
      @log "AFTER ", label
    ret

  logResults: (category, url, timeSpent) ->
    # send results to the provided logger or console.log
    if @analyticsLogger
      @analyticsLogger.logTiming(category, url, timeSpent, null)
    else
      console.log category, url, timeSpent

  checkLogPoints: ->
    _.each @logPoints, (lp) =>
      if not lp.logged
       # call the log point funciton, if it returns true
       # we've met the condition to log
       if lp.func.apply()
         lp.logged = true
         now = new Date().getTime()
         timeSpent = now - @queue[0].timeTag
         @log(@runName + " : LOG POINT " + lp.name, lp.name, timeSpent)
         @logResults(@runName + " : LOG POINT " + lp.name, lp.name, timeSpent)

  addObject: (obj) ->
    rec = {}
    rec.timeTag = new Date().getTime()
    rec.obj = obj
    @queue.push rec
    @checkLogPoints()
    @setDoneTimer()

  cleanup: ->
    clearTimeout @checkTimer if @checkTimer
    @queue = []
    @logPoints = []

  setDoneTimer: ->
    clearTimeout @checkTimer if @checkTimer
    @checkTimer = _.delay @checkDone, 500

  checkDone: =>
    now = new Date().getTime()
    last = _.last(@queue)
    if last
      delta = now - last.timeTag
      @log "time since last", delta
      if delta > @doneTiming
        @stop()
        @log ">>>>>>>>>>>>>>>>>>PAGE RENDER DONE"
        elapsed = last.timeTag - @queue[0].timeTag
        @log("RENDER TIME", @runName, last.timeTag - @queue[0].timeTag)
        # put off report for a while to avoid spoiling other perf analysis tools
        # like webpagetest that listens for quiet periods to determine test-complete
        _.delay @issueReport, 5000, elapsed
        @cleanup()
      else
        @setDoneTimer()

  issueReport: (elapsed) =>
    @logResults(@runName, @url, elapsed)
