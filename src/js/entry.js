export default class Entry {
  constructor(data) {
    if (data == null) { data = {}; }
    this.time = data.time;
    this.note = data.note;
  }
}
