# global screenfull

class Entry
  constructor: (data = {}) ->
    @time = data.time
    @note = data.note

class EntryView
  constructor: (@container, @model) ->
    @elemEntries = @find('.entries')
    @elem = @bindActions(@render())

  render: ->
    elem = @createElement()
    elem.querySelector('.note').innerHTML = @model.note
    elem.querySelector('.time-remaining').innerHTML = @model.time
    elem

  bindActions: (elem) ->
    elem.addEventListener('click', (event) =>
      if event.target.classList.contains('note')
        @elem.classList.add('editing')
        @elem.querySelector('[type=text]').select()

      if event.target.classList.contains('note-editing')
        @elem.classList.remove('editing')

      if event.target.classList.contains('close')
        @removeElement()
    )

    elem.addEventListener('submit', (event) =>
      event.preventDefault()

      @model.note = event.target['editing-entry'].value
      @elem.classList.remove('editing')
      @render()
    )

    elem

  ###
  @private
  @method strip
  @todo Reuse in `View` or `Utils` class.
  ###
  strip: (text) ->
    text.replace('\s\s+', ' ')

  ###
  @private
  @method find
  @todo This is duplicated in `Pomodoro`. Reuse it in a `View` class.
  ###
  find: (selector) ->
    elem = @container.querySelector(selector)
    throw new Error("Element not found #{selector}") unless elem
    elem

  ###
  @private
  @method createElement
  ###
  createElement: ->
    return @elem if @elem?

    @elem = document.createElement('li')
    @elem.classList.add('entry')

    @elem.innerHTML = @strip("""
      <span class="note">#{@model.note}</span>
      <form class="note-entry">
        <input type="text" value="#{@model.note}" name="editing-entry" />
        <input type="submit" class="small button" value="Save" />
      </form>
      <div class="info-area">
        <span class="time-remaining">#{@model.time}</span>
        <button class="close small button">x</button>
      </div>
    """)

    @elemEntries.appendChild(@elem)

    @elem

  ###
  @private
  @method removeElement
  ###
  removeElement: ->
    @elemEntries.removeChild(@elem)

class Pomodoro
  setting:
    POMODORO: 25 * 60 * 1000
    SHORT:    5  * 60 * 1000
    LONG:     10 * 60 * 1000

  constructor: (@container) ->
    @elemPomodoro     = @find('.button-group.length .pomodoro-time')
    @elemShortBreak   = @find('.button-group.length .short-break')
    @elemLongBreak    = @find('.button-group.length .long-break')
    @elemStartTimer   = @find('.button-group.control .start')
    @elemStopTimer    = @find('.button-group.control .stop')
    @elemResetTimer   = @find('.button-group.control .reset')
    @elemFullscreen   = @find('.button-group.control .fullscreen')
    @elemAboutButton  = @find('.share.about')
    @elemAbout        = @find('.about-area')
    @elemTimer        = @find('.timer')
    @elemTimerWrapper = @find('.timer-wrapper')
    @elemEntries      = @find('.entries')

    @defaultTitle     = document.title
    @notifySound      = @loadSound('notify.mp3')
    @startTime        = null
    @updateIntervalID = null
    @delayIntervalID  = null
    @currentEntry     = null
    @pastElapsedTime  = 0
    @timeSetting      = @setting.POMODORO

    @showAbout() if @hasAboutAnchor()
    @showFullscreenButton() if screenfull.enabled
    @showTime()
    @bindActions()

    window.addEventListener('resize', @adjustEntriesWidth.bind(this))
    @adjustEntriesWidth()

  ###
  @private
  @method adjustEntriesWidth
  @todo This is a temporary hack. Update this with better CSS.
  ###
  adjustEntriesWidth: ->
    buttonStyle  = window.getComputedStyle(@find('.button-group:last-child'), null)
    buttonWidth  = buttonStyle.getPropertyValue('width')
    wrapperStyle = window.getComputedStyle(@elemTimerWrapper, null)
    fullScreen   = parseInt(wrapperStyle.getPropertyValue('width'), 10) is window.innerWidth
    wrapperWidth = @elemTimerWrapper.clientWidth + 'px'

    @elemEntries.style.width = if fullScreen then buttonWidth else wrapperWidth

  ###
  @private
  @method hasAboutAnchor
  ###
  hasAboutAnchor: ->
    window.location.hash is '#about'

  ###
  @private
  @method showFullscreenButton
  ###
  showFullscreenButton: ->
    @elemFullscreen.classList.remove('hidden')

  ###
  @private
  @method toggleFullscreen
  ###
  toggleFullscreen: ->
    screenfull.toggle()

  ###
  @private
  @method showAbout
  ###
  showAbout: ->
    window.requestAnimationFrame(=>
      @elemAbout.style.display = 'block'

      window.requestAnimationFrame(->
        document.body.classList.remove('about-invisible')
      )
    )

  ###
  @private
  @method updateFullscreenClass
  ###
  updateFullscreenClass: ->
    if screenfull.isFullscreen
      document.body.classList.add('fullscreen')
    else
      document.body.classList.remove('fullscreen')

  ###
  @private
  @method loadSound
  ###
  loadSound: (path) ->
    sound = new Audio(path)
    sound.preload = 'auto'
    sound.load()
    sound

  ###
  @private
  @method bindActions
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
  @method find
  @todo This is duplicated in `EntryView`. Reuse it.
  ###
  find: (selector) ->
    elem = @container.querySelector(selector)
    throw new Error("Element not found #{selector}") unless elem
    elem

  ###
  @private
  @method running
  ###
  running: ->
    @delayIntervalID? or @updateIntervalID?

  ###
  @private
  @method addEntry
  ###
  addEntry: (time) ->
    note =
      switch time
        when @setting.POMODORO then 'Pomodoro'
        when @setting.SHORT    then 'Short Break'
        when @setting.LONG     then 'Long Break'

    entry = new Entry(note: note, time: @formatTime(0))
    view  = new EntryView(@container, entry)
    view

  ###
  @private
  @method updateCurrentEntry
  ###
  updateCurrentEntry: (remaining) ->
    return unless @currentEntry?
    @currentEntry.model.time = @formatTime(remaining)
    @currentEntry.render()

  ###
  @private
  @method startTimer
  ###
  startTimer: (delay) ->
    return if @running()

    # NOTE(maros): We have to pad this with 1000ms because of the artificial
    # `timeDelay` we sometimes introduce below.
    return @resetTimer() if (@pastElapsedTime + 1000) > @timeSetting

    document.title = @defaultTitle

    @showTime()

    @currentEntry = @addEntry(@timeSetting) if @pastElapsedTime is 0
    timeDelay = if delay then 1000 else 0

    clearInterval(@delayIntervalID)

    @delayIntervalID = setTimeout =>
      @startTime = Date.now()
      @updateIntervalID = setInterval(=>
        time      = @pastElapsedTime + (Date.now() - @startTime)
        remaining = @subtractTime(time)

        @updateCurrentEntry(time + 1000)
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
  @method stopTimer
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
  @method resetTimer
  ###
  resetTimer: (timeSetting) ->
    @timeSetting = timeSetting if timeSetting?
    @stopTimer()
    @pastElapsedTime = 0
    @startTimer(true)

  ###
  @private
  @method formatTime
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
  @method subtractTime
  ###
  subtractTime: (timeElapsed) ->
    remaining = Math.max(0, @timeSetting - timeElapsed)
    @elemTimer.innerHTML = @formatTime(remaining)
    remaining

  ###
  @private
  @method showTime
  ###
  showTime: ->
    @subtractTime(@pastElapsedTime)

new Pomodoro(document.querySelector('.pomodoro'))
