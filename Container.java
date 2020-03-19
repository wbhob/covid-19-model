public class Container {
  public int x, y, height, width;
  
  public boolean isOnBoundaryX(float x) {
     return x < this.x || x > this.width + this.x;
  }
    
  public boolean isOnBoundaryY(float y) {
     return y < this.y || y > this.height + this.y;
  }
} 
