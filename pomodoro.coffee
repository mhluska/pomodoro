class Pomodoro
  setting: 
    POMODORO: 25 * 60 * 1000
    SHORT:    5  * 60 * 1000
    LONG:     10 * 60 * 1000

  constructor: (@container) ->
    @elemPomodoro   = @find('.button-group.length .pomodoro')
    @elemShortBreak = @find('.button-group.length .short-break')
    @elemLongBreak  = @find('.button-group.length .long-break')
    @elemStartTimer = @find('.button-group.control .start')
    @elemStopTimer  = @find('.button-group.control .stop')
    @elemResetTimer = @find('.button-group.control .reset')
    @elemTimer      = @find('.timer')

    @startTime        = null
    @updateIntervalID = null
    @pastElapsedTime  = 0
    @timeSetting      = @setting.POMODORO

    @showTime()
    @bindActions()

  ###
  @private
  ###
  bindActions: ->
    @elemPomodoro.addEventListener('click',   => @resetTimer(@setting.POMODORO))
    @elemShortBreak.addEventListener('click', => @resetTimer(@setting.SHORT))
    @elemLongBreak.addEventListener('click',  => @resetTimer(@setting.LONG))
    @elemStartTimer.addEventListener('click', => @startTimer())
    @elemStopTimer.addEventListener('click',  => @stopTimer())
    @elemResetTimer.addEventListener('click', => @resetTimer(@timeSetting))

  ###
  @private
  ###
  find: (selector) ->
    elem = @container.querySelector(selector)
    throw new Error("Element not found #{selector}") unless elem
    elem

  ###
  @private
  ###
  running: ->
    @updateIntervalID?

  ###
  @private
  ###
  startTimer: ->
    return if @running()

    @showTime()
    @startTime = Date.now()
    @updateIntervalID = setInterval(=>
      @subtractTime(@pastElapsedTime + (Date.now() - @startTime))
    , 1000)

  ###
  @private
  ###
  stopTimer: ->
    return unless @running()
    clearInterval(@updateIntervalID)
    @updateIntervalID = null
    @pastElapsedTime += Date.now() - @startTime
    @startTime        = null

  ###
  @private
  ###
  resetTimer: (@timeSetting) ->
    @stopTimer()
    @startTimer()

  ###
  @private
  @param [number] time The time in milliseconds to format
  ###
  formatTime: (time) ->
    totalSeconds = time / 1000
    minutes = Math.floor(totalSeconds / 60).toString()
    seconds = Math.ceil(totalSeconds % 60).toString()
    seconds = '0' + seconds if seconds.length is 1
    minutes + ':' + seconds

  ###
  @private
  ###
  subtractTime: (timeElapsed) ->
    remaining = Math.max(0, @timeSetting - timeElapsed)
    @elemTimer.innerHTML = @formatTime(remaining)

  ###
  @private
  ###
  showTime: ->
    @subtractTime(@pastElapsedTime)

new Pomodoro(document.querySelector('body.pomodoro'))
