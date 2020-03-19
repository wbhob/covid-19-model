public enum State {
  HEALTHY, INFECTED, RECOVERED, DEAD;
  
  public boolean isActive() {
    return this != DEAD;
  }
}
