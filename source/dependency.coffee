class window.DependencyChecker
  constructor: (@container) ->
    @elemTimerWrapper = @container.querySelector('.timer-wrapper')
    @elemMessage      = @container.querySelector('.message')

    @container.addEventListener('click', (event) =>
      return unless event.target.classList.contains('use-anyway')
      @elemTimerWrapper.classList.remove('disabled')
    )

  check: ->
    return @notify('fullscreen')   unless @hasFullscreen()
    return @notify('localStorage') unless @hasLocalStorage()

  ###
  @private
  @method hasLocalStorage
  ###
  hasLocalStorage: ->
    test = 'test'
    try
      localStorage.setItem(test, test)
      localStorage.removeItem(test)
      return true
    catch
      return false

  ###
  @private
  @method hasLocalStorage
  ###
  hasFullscreen: ->
    screenfull.enabled?

  ###
  @private
  @method notify
  ###
  notify: (item) ->
    message  = "Looks like <em>#{item}</em> is not supported. Consider using a "
    message += "<a href='https://www.google.com/chrome/browser/' target='_blank'>modern browser</a>."
    message += "<button class='use-anyway big button'>Use anyway</button>"

    @elemTimerWrapper.classList.add('disabled')
    @elemMessage.innerHTML = message
