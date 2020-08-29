import screenfull from 'screenfull';

import './web-fonts.js';
import DependencyChecker from './dependency-checker.js';
import Entry from './entry.js';
import EntryView from './entry-view.js';
import formatTime from './utils/format-time';

import '../css/pomodoro.scss';

/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */

class Pomodoro {
  static initClass() {
    this.prototype.setting = {
      POMODORO: 25 * 60 * 1000,
      SHORT:    5  * 60 * 1000,
      LONG:     10 * 60 * 1000
    };
  }

  constructor(container1) {
    this.container = container1;
    this.elemPomodoro     = this.find('.button-group.length .pomodoro-time');
    this.elemShortBreak   = this.find('.button-group.length .short-break');
    this.elemLongBreak    = this.find('.button-group.length .long-break');
    this.elemStartTimer   = this.find('.button-group.control .start');
    this.elemStopTimer    = this.find('.button-group.control .stop');
    this.elemResetTimer   = this.find('.button-group.control .reset');
    this.elemFullscreen   = this.find('.button-group.control .fullscreen');
    this.elemAboutButton  = this.find('.share.about');
    this.elemAbout        = this.find('.about-area');
    this.elemTimer        = this.find('.timer');
    this.elemTimerWrapper = this.find('.timer-wrapper');
    this.elemEntries      = this.find('.entries');
    this.elemHeader       = this.find('.pomodoro header');

    this.defaultTitle     = document.title;
    this.notifySound      = this.loadSound(require('../audio/notify.mp3').default);
    this.cachedHeight     = {};
    this.startTime        = null;
    this.updateIntervalID = null;
    this.delayIntervalID  = null;
    this.currentEntry     = null;
    this.entries          = [];
    this.pastElapsedTime  = 0;
    this.timeSetting      = this.setting.POMODORO;

    if (this.hasAboutAnchor()) { this.showAbout(); }
    if (screenfull.isEnabled) { this.showFullscreenButton(); }

    this.showTime();
    this.bindActions();
    this.updateVerticalAlignment();

    this.adjustEntriesWidth();
    this.loadEntries();
  }

  /*
  @private
  @method outerHeight
  @todo Move this to a utils class.
  */
  outerHeight(element, options) {
    if (options == null) { options = {}; }
    if (options.padding == null) { options.padding = true; }
    if (options.margin == null) {  options.margin = true; }

    const styles  = window.getComputedStyle(element);
    let margin  = 0;
    if (options.margin) { margin  = parseFloat(styles.marginTop) + parseFloat(styles.marginBottom); }
    let padding = 0;
    if (options.padding) { padding = parseFloat(styles.paddingTop) + parseFloat(styles.paddingBottom); }
    const border  = parseFloat(styles.borderTop) + parseFloat(styles.borderBottom);

    return element.clientHeight + margin + padding + border;
  }

  /*
  @private
  @method adjustEntriesWidth
  @todo This is a temporary hack. Update this with better CSS.
  */
  adjustEntriesWidth() {
    const buttonStyle  = window.getComputedStyle(this.find('.button-group:last-child'), null);
    const buttonWidth  = buttonStyle.getPropertyValue('width');
    const wrapperStyle = window.getComputedStyle(this.elemTimerWrapper, null);
    const fullScreen   = parseInt(wrapperStyle.getPropertyValue('width'), 10) === window.innerWidth;
    const wrapperWidth = this.elemTimerWrapper.clientWidth + 'px';

    return this.elemEntries.style.width = fullScreen ? buttonWidth : wrapperWidth;
  }

  /*
  @private
  @method updateVerticalAlignment
  @todo This is a temporary hack. Find a way to align this with CSS.
  */
  updateVerticalAlignment() {
    if (this.cachedHeight.header == null) { this.cachedHeight.header = this.outerHeight(this.elemHeader, {padding: false}) + 2; }
    return this.elemHeader.style['margin-top'] = -(this.cachedHeight.header) + 'px';
  }

  /*
  @private
  @method hasAboutAnchor
  */
  hasAboutAnchor() {
    return window.location.hash === '#about';
  }

  /*
  @private
  @method showFullscreenButton
  */
  showFullscreenButton() {
    return this.elemFullscreen.classList.remove('hidden');
  }

  /*
  @private
  @method toggleFullscreen
  */
  toggleFullscreen() {
    return screenfull.toggle();
  }

  /*
  @private
  @method updateFullscreenClass
  */
  updateFullscreenClass(options) {
    if (options == null) { options = {}; }
    if (options.enable || screenfull.isFullscreen) {
      return document.body.classList.add('fullscreen');
    } else {
      return document.body.classList.remove('fullscreen');
    }
  }

  /*
  @private
  @method showAbout
  */
  showAbout() {
    return window.requestAnimationFrame(() => {
      this.elemAbout.classList.remove('hidden');

      return window.requestAnimationFrame(() => {
        this.elemAbout.classList.remove('invisible');
        return this.elemAbout.scrollIntoView();
      });
    });
  }

  /*
  @private
  @method loadSound
  */
  loadSound(path) {
    const sound = new Audio(path);
    sound.preload = 'auto';
    sound.load();
    return sound;
  }

  /*
  @private
  @method bindActions
  */
  bindActions() {
    this.elemPomodoro.addEventListener('click',      () => this.resetTimer(this.setting.POMODORO));
    this.elemShortBreak.addEventListener('click',    () => this.resetTimer(this.setting.SHORT));
    this.elemLongBreak.addEventListener('click',     () => this.resetTimer(this.setting.LONG));
    this.elemStartTimer.addEventListener('click',    () => this.startTimer());
    this.elemStopTimer.addEventListener('click',     () => this.stopTimer());
    this.elemResetTimer.addEventListener('click',    () => this.resetTimer(this.timeSetting));
    this.elemFullscreen.addEventListener('click',    () => this.toggleFullscreen());
    this.elemAboutButton.addEventListener('click',   () => this.showAbout());
    this.container.addEventListener('click', event => this.removeEntryByEvent(event));

    if (screenfull.isEnabled) { document.addEventListener(screenfull.raw.fullscreenchange, this.updateFullscreenClass); }

    window.addEventListener('resize', this.adjustEntriesWidth.bind(this));
    return window.addEventListener('beforeunload', this.saveEntries.bind(this));
  }

  /*
  @private
  @method find
  @todo This is duplicated in `EntryView`. Reuse it.
  */
  find(selector) {
    const elem = this.container.querySelector(selector);
    if (!elem) { throw new Error(`Element not found ${selector}`); }
    return elem;
  }

  /*
  @private
  @method running
  */
  running() {
    return (this.delayIntervalID != null) || (this.updateIntervalID != null);
  }

  /*
  @private
  @method addEntry
  */
  addEntry(options) {
    if (options == null) { options = {}; }
    if (options.time == null) { options.time = 0; }
    if (options.note == null) { options.note = ''; }

    const entry = new Entry({note: options.note, time: options.time});
    const view  = new EntryView(this.container, entry);

    this.entries.push(view);
    this.currentEntry = view;

    return view;
  }

  /*
  @private
  @method addNamedEntry
  */
  addNamedEntry(timeSetting) {
    const note =
      (() => { switch (timeSetting) {
        case this.setting.POMODORO: return 'Pomodoro';
        case this.setting.SHORT:    return 'Short Break';
        case this.setting.LONG:     return 'Long Break';
      } })();

    return this.addEntry({time: 0, note});
  }

  /*
  @private
  @method removeEntryByIndex
  */
  removeEntryByIndex(index) {
    const view = this.entries.splice(index, 1)[0];
    return view.elem.parentNode.removeChild(view.elem);
  }

  /*
  @private
  @method removeEntryByEvent
  */
  removeEntryByEvent(event) {
    if (!event.target.classList.contains('close')) { return; }

    const item     = event.target.parentNode.parentNode;
    const {
      children
    } = item.parentNode;
    const index    = Array.prototype.indexOf.call(children, item);

    return this.removeEntryByIndex(children.length - index - 1);
  }

  /*
  @private
  @method updateCurrentEntry
  */
  updateCurrentEntry(remaining) {
    if (this.currentEntry == null) { return; }
    this.currentEntry.model.time = remaining;
    return this.currentEntry.render();
  }

  /*
  @private
  @method saveEntries
  */
  saveEntries() {
    return localStorage.setItem('entries', JSON.stringify(Array.from(this.entries).map((e) => e.model)));
  }

  /*
  @private
  @method loadEntries
  */
  loadEntries() {
    return Array.from(JSON.parse(localStorage.getItem('entries'))).map((entry) =>
      this.addEntry({time: entry.time, note: entry.note}));
  }

  /*
  @private
  @method startTimer
  */
  startTimer(delay) {
    if (this.running()) { return; }

    this.updateFullscreenClass({enable: true});

    // NOTE(maros): We have to pad this with 1000ms because of the artificial
    // `timeDelay` we sometimes introduce below.
    if ((this.pastElapsedTime + 1000) > this.timeSetting) { return this.resetTimer(); }

    document.title = this.defaultTitle;

    this.showTime();

    if (this.pastElapsedTime === 0) { this.addNamedEntry(this.timeSetting); }

    const timeDelay = delay ? 1000 : 0;

    clearInterval(this.delayIntervalID);

    return this.delayIntervalID = setTimeout(() => {
      this.startTime = Date.now();
      return this.updateIntervalID = setInterval(() => {
        const time      = this.pastElapsedTime + (Date.now() - this.startTime);
        const remaining = this.subtractTime(time);

        this.updateCurrentEntry(time + 1000);
        if (remaining < 1000) { return this.alert(); }
      }

      , (1000 / 30));
    }
    , timeDelay);
  }

  /*
  @private
  @method alert
  */
  alert() {
    this.notifySound.currentTime = 0;
    this.notifySound.play();
    this.stopTimer();

    const message = (this.timeSetting / 1000 / 60) + ' minutes elapsed!';
    document.title = message;
    return alert(message);
  }

  /*
  @private
  @method stopTimer
  */
  stopTimer() {
    if (!this.running()) { return; }
    this.updateFullscreenClass({enable: false});
    clearInterval(this.delayIntervalID);
    clearInterval(this.updateIntervalID);
    this.delayIntervalID  = null;
    this.updateIntervalID = null;
    this.pastElapsedTime += Date.now() - this.startTime;
    return this.startTime        = null;
  }

  /*
  @private
  @method resetTimer
  */
  resetTimer(timeSetting) {
    if (timeSetting != null) { this.timeSetting = timeSetting; }
    this.stopTimer();
    this.pastElapsedTime = 0;
    return this.startTimer(true);
  }

  /*
  @private
  @method subtractTime
  */
  subtractTime(timeElapsed) {
    const remaining = Math.max(0, this.timeSetting - timeElapsed);
    this.elemTimer.innerHTML = formatTime(remaining);
    return remaining;
  }

  /*
  @private
  @method showTime
  */
  showTime() {
    return this.subtractTime(this.pastElapsedTime);
  }
}
Pomodoro.initClass();

const container = document.querySelector('.pomodoro');

if (container) {
  (new DependencyChecker(container)).check();
  new Pomodoro(container);
} else {
  console.warn('No element with `pomodoro` class found');
}
