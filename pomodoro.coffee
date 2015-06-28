class Pomodoro
  LENGTH_POMODORO: 25 * 60
  LENGTH_SHORT: 5 * 60
  LENGTH_LONG: 10 * 60

  constructor: (@container) ->
    @elemPomodoro   = @find('.button-group.length .pomodoro')
    @elemShortBreak = @find('.button-group.length .short-break')
    @elemLongBreak  = @find('.button-group.length .long-break')
    @elemStartTimer = @find('.button-group.control .start')
    @elemStopTimer  = @find('.button-group.control .stop')
    @elemResetTimer = @find('.button-group.control .reset')
    @elemTimer      = @find('.timer')

    @countdownIntervalID = null
    @timeSetting = @LENGTH_POMODORO
    @currentTime = @setTime(@LENGTH_POMODORO)

    @bindActions()

  ###
  @private
  ###
  bindActions: ->
    @elemPomodoro.addEventListener('click',   => @resetTimer(@LENGTH_POMODORO))
    @elemShortBreak.addEventListener('click', => @resetTimer(@LENGTH_SHORT))
    @elemLongBreak.addEventListener('click',  => @resetTimer(@LENGTH_LONG))
    @elemStartTimer.addEventListener('click', => @startTimer())
    @elemStopTimer.addEventListener('click',  => @stopTimer())
    @elemResetTimer.addEventListener('click', => @resetTimer())

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
    @countdownIntervalID?

  ###
  @private
  ###
  startTimer: ->
    return if @running()
    @countdownTimer(@currentTime)

  ###
  @private
  ###
  stopTimer: ->
    return unless @running()
    clearInterval(@countdownIntervalID)
    @countdownIntervalID = null

  ###
  @private
  ###
  resetTimer: (seconds) ->
    @timeSetting = seconds if seconds
    @stopTimer()
    @countdownTimer(@timeSetting)

  ###
  @private
  ###
  countdownTimer: (seconds) ->
    @currentTime = @setTime(seconds)

    return if seconds <= 0

    @countdownIntervalID = setTimeout(=>
      @countdownTimer(seconds - 1)
    , 1000)

  ###
  @private
  ###
  formatTime: (totalSeconds) ->
    minutes = Math.floor(totalSeconds / 60).toString()
    seconds = (totalSeconds % 60).toString()
    seconds = '0' + seconds if seconds.length is 1

    minutes + ':' + seconds

  ###
  @private
  ###
  setTime: (seconds) ->
    @elemTimer.innerHTML = @formatTime(seconds)
    seconds

new Pomodoro(document.querySelector('body.pomodoro'))
