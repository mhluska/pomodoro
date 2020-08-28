import formatTime from './utils/format-time';

export default class EntryView {
  constructor(container1, model) {
    this.container = container1;
    this.model = model;
    this.elemEntries = this.find('.entries');
    this.elem = this.bindActions(this.render());
  }

  render() {
    const elem = this.createElement();
    elem.querySelector('.note').innerHTML = this.model.note;
    elem.querySelector('.time-remaining').innerHTML = formatTime(this.model.time);
    return elem;
  }

  bindActions(elem) {
    elem.addEventListener('click', event => {
      if (event.target.classList.contains('note')) {
        this.elem.classList.add('editing');
        this.elem.querySelector('[type=text]').select();
      }

      if (event.target.classList.contains('note-editing')) {
        return this.elem.classList.remove('editing');
      }
    });

    elem.addEventListener('submit', event => {
      event.preventDefault();

      this.model.note = event.target['editing-entry'].value;
      this.elem.classList.remove('editing');
      return this.render();
    });

    return elem;
  }

  /*
  @private
  @method strip
  @todo Reuse in `View` or `Utils` class.
  */
  strip(text) {
    return text.replace('\s\s+', ' ');
  }

  /*
  @private
  @method find
  @todo This is duplicated in `Pomodoro`. Reuse it in a `View` class.
  */
  find(selector) {
    const elem = this.container.querySelector(selector);
    if (!elem) { throw new Error(`Element not found ${selector}`); }
    return elem;
  }

  /*
  @private
  @method createElement
  */
  createElement() {
    if (this.elem != null) { return this.elem; }

    this.elem = document.createElement('li');
    this.elem.classList.add('entry');

    this.elem.innerHTML = this.strip(`\
<span class="note">${this.model.note}</span>
<form class="note-entry">
  <input type="text" value="${this.model.note}" name="editing-entry" /><input type="submit" class="small button" value="Save" />
</form>
<div class="info-area">
  <span class="time-remaining">${this.model.time}</span>
  <button class="close small button">✕</button>
</div>\
`);

    this.elemEntries.insertBefore(this.elem, this.elemEntries.childNodes[0]);

    return this.elem;
  }
}
