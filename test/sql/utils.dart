int minTime(int min) {
  if (min == 0) return 1; // has to be above 1
  return 1000 * 60 * min;
}
