# global screenfull

class Pomodoro
  setting:
    POMODORO: 25 * 60 * 1000
    SHORT:    5  * 60 * 1000
    LONG:     10 * 60 * 1000

  constructor: (@container) ->
    @elemPomodoro    = @find('.button-group.length .pomodoro-time')
    @elemShortBreak  = @find('.button-group.length .short-break')
    @elemLongBreak   = @find('.button-group.length .long-break')
    @elemStartTimer  = @find('.button-group.control .start')
    @elemStopTimer   = @find('.button-group.control .stop')
    @elemResetTimer  = @find('.button-group.control .reset')
    @elemFullscreen  = @find('.button-group.control .fullscreen')
    @elemAboutButton = @find('.share.about')
    @elemAbout       = @find('.about-area')
    @elemTimer       = @find('.timer')

    @defaultTitle     = document.title
    @notifySound      = @loadSound('notify.mp3')
    @startTime        = null
    @updateIntervalID = null
    @delayIntervalID  = null
    @pastElapsedTime  = 0
    @timeSetting      = @setting.POMODORO

    @showAbout() if @hasAboutAnchor()
    @showFullscreenButton() if screenfull.enabled
    @showTime()
    @bindActions()

  ###
  @private
  ###
  hasAboutAnchor: ->
    window.location.hash is '#about'

  ###
  @private
  ###
  showFullscreenButton: ->
    @elemFullscreen.classList.remove('hidden')

  ###
  @private
  ###
  toggleFullscreen: ->
    screenfull.toggle()

  ###
  @private
  ###
  showAbout: ->
    document.body.classList.remove('about-invisible')

  ###
  @private
  ###
  updateFullscreenClass: ->
    if screenfull.isFullscreen
      document.body.classList.add('fullscreen')
    else
      document.body.classList.remove('fullscreen')

  ###
  @private
  ###
  loadSound: (path) ->
    sound = new Audio(path)
    sound.preload = 'auto'
    sound.load()
    sound

  ###
  @private
  ###
  bindActions: ->
    @elemPomodoro.addEventListener('click',    => @resetTimer(@setting.POMODORO))
    @elemShortBreak.addEventListener('click',  => @resetTimer(@setting.SHORT))
    @elemLongBreak.addEventListener('click',   => @resetTimer(@setting.LONG))
    @elemStartTimer.addEventListener('click',  => @startTimer())
    @elemStopTimer.addEventListener('click',   => @stopTimer())
    @elemResetTimer.addEventListener('click',  => @resetTimer(@timeSetting))
    @elemFullscreen.addEventListener('click',  => @toggleFullscreen())
    @elemAboutButton.addEventListener('click', => @showAbout())

    document.addEventListener(screenfull.raw.fullscreenchange, @updateFullscreenClass) if screenfull.enabled

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
    @delayIntervalID? or @updateIntervalID?

  ###
  @private
  ###
  startTimer: (delay) ->
    return if @running()

    # NOTE(maros): We have to pad this with 1000ms because of the artificial
    # `timeDelay` we sometimes introduce below.
    return @resetTimer() if (@pastElapsedTime + 1000) > @timeSetting

    document.title = @defaultTitle

    @showTime()

    timeDelay = if delay then 1000 else 0
    clearInterval(@delayIntervalID)

    @delayIntervalID = setTimeout =>
      @startTime = Date.now()
      @updateIntervalID = setInterval(=>
        remaining = @subtractTime(@pastElapsedTime + (Date.now() - @startTime))

        @alert() if remaining < 1000

      , (1000 / 30))
    , timeDelay

  ###
  @private
  @method alert
  ###
  alert: ->
    @notifySound.currentTime = 0
    @notifySound.play()
    @stopTimer()

    message = (@timeSetting / 1000 / 60) + ' minutes elapsed!'
    document.title = message
    alert(message)

  ###
  @private
  ###
  stopTimer: ->
    return unless @running()
    clearInterval(@delayIntervalID)
    clearInterval(@updateIntervalID)
    @delayIntervalID  = null
    @updateIntervalID = null
    @pastElapsedTime += Date.now() - @startTime
    @startTime        = null

  ###
  @private
  ###
  resetTimer: (timeSetting) ->
    @timeSetting = timeSetting if timeSetting?
    @stopTimer()
    @pastElapsedTime = 0
    @startTimer(true)

  ###
  @private
  @param [number] time The time in milliseconds to format
  ###
  formatTime: (time) ->
    totalSeconds = time / 1000
    minutes = Math.floor(totalSeconds / 60).toString()
    seconds = Math.floor(totalSeconds % 60).toString()
    seconds = '0' + seconds if seconds.length is 1
    minutes + ':' + seconds

  ###
  @private
  ###
  subtractTime: (timeElapsed) ->
    remaining = Math.max(0, @timeSetting - timeElapsed)
    @elemTimer.innerHTML = @formatTime(remaining)
    remaining

  ###
  @private
  ###
  showTime: ->
    @subtractTime(@pastElapsedTime)

new Pomodoro(document.querySelector('.pomodoro'))
