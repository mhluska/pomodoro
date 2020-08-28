/*
@method formatTime
@param [number] time The time in milliseconds to format
*/
export default function(time) {
  const totalSeconds = time / 1000;
  const minutes = Math.floor(totalSeconds / 60).toString();
  let seconds = Math.floor(totalSeconds % 60).toString();
  if (seconds.length === 1) { seconds = '0' + seconds; }
  return minutes + ':' + seconds;
};
