import grafica.*;
import java.util.ArrayList;

final int infectionChance = Variables.infectionChance;
final int recoveryChance = Variables.recoveryChance;

final int isolationChance = Variables.isolationChance;

final int sicknessLength = Variables.sicknessLength;
final int blobCount = Variables.blobCount;

int deadCount, recoveredCount, healthyCount = blobCount, infectedCount;

Container simulationContainer  = new Container();
Container graphContainer = new Container();
GPlot plot;

GPointsArray healthyPoints = new GPointsArray(),
  infectedPoints = new GPointsArray(),
  recoveredPoints = new GPointsArray(),
  deadPoints = new GPointsArray();

int circleRadius = 5;

Blob[] blobs;

void setup() {
  size(1200, 700);
  
  simulationContainer.x=0;
  simulationContainer.y=0;
  simulationContainer.width=width/2;
  simulationContainer.height=height-40;

  graphContainer.x=simulationContainer.x + simulationContainer.width;
  graphContainer.y=0;
  graphContainer.width=width/2 - 100;
  graphContainer.height=height-40 -100;

  plot = new GPlot(this);

  plot.setPos(graphContainer.x,graphContainer.y);
  plot.setDim(graphContainer.width,graphContainer.height);
  
  blobs = new Blob[blobCount];
  
  for (int i = 0; i < blobs.length; i++){
    blobs[i]= new Blob(State.HEALTHY, width, height);

    if (i != blobs.length -1) {
      float chance = random(100);
      if (chance < isolationChance) {
        blobs[i].isolate();
      }
    }
    else {
      blobs[i].infect();
    }
  }


  plot.setPoints(healthyPoints);
  plot.setLineColor(color(0,0,0));
  plot.addLayer("infected", infectedPoints);
  plot.getLayer("infected").setLineColor(color(0,255,0));
  plot.addLayer("recovered", recoveredPoints);
  plot.getLayer("recovered").setLineColor(color(150,0,150));
  plot.addLayer("dead", deadPoints);
  plot.getLayer("dead").setLineColor(color(255,0,0));
}

void draw() {
  background(0);
  
  for (int i = 0; i < blobs.length; i++){
    blobs[i].initFrame();
    switch(blobs[i].getState()){ 
      case HEALTHY:
        stroke(0,0,0);
        fill(200,200,200);
        break;
      case INFECTED:
        fill(0,255,0);
        break;
      case RECOVERED:
        fill(150,0,150);
        break;
    }
    
    if (blobs[i].isActive()) {
      circle(blobs[i].position.x, blobs[i].position.y, circleRadius*2);
      blobs[i].move();
    }
    handleCollisions(blobs[i]);    
  }
  
  textSize(20);
  fill(255,255,255);
  text("HEALTHY: " + healthyCount, 10, height-10);
  
  fill(0,255,0);
  text("INFECTED: " + infectedCount, 180, height-10);
   
  fill(150,0,150);
  text("RECOVERED: " + recoveredCount, 350, height-10);
  
  fill(255,0,0);
  text("DEAD: " + deadCount, 550, height-10);

if (frameCount % 10 == 0) {
  healthyPoints.add( frameCount, healthyCount);
  infectedPoints.add( frameCount, infectedCount);
  recoveredPoints.add( frameCount, recoveredCount);
  deadPoints.add( frameCount, deadCount);
}

  plot.setPoints(healthyPoints);
  plot.setPointColor(color(0,0,0));
  plot.getLayer("infected").setPoints(infectedPoints);
  plot.getLayer("infected").setLineColor(color(0,255,0));
  plot.getLayer("infected").setPointColor(color(0,255,0));
  plot.getLayer("recovered").setPoints(recoveredPoints);
  plot.getLayer("recovered").setLineColor(color(150,0,150));
  plot.getLayer("recovered").setPointColor(color(150,0,150));
  plot.getLayer("dead").setPoints(deadPoints);
  plot.getLayer("dead").setLineColor(color(255,0,0));
  plot.getLayer("dead").setPointColor(color(255,0,0));


  plot.beginDraw();
  plot.drawBackground();
  plot.drawBox();
  plot.drawXAxis();
  plot.drawYAxis();
  plot.drawTitle();
  plot.drawPoints();
  plot.endDraw();
}

void handleCollisions(Blob blob) {
  for (int i = 0; i < blobs.length; i++) {
    if (blobs[i] == blob) continue;
    else {
      if (dist(blob.position.x, blob.position.y, blobs[i].position.x, blobs[i].position.y) < circleRadius*2) {
        blob.collide(blobs[i]);
      }
    }
  }
}

class Blob {
  public PVector position;
  public PVector velocity;
  
  private State state;
  
  public boolean hasCollided;
  private boolean isolated = false;
  
  private int frameCountSinceSick = 0;
  private int numPeopleInfected = 0;
  
  public Blob(State state, int width, int height) {
    this.position = new PVector(random(simulationContainer.x + 1, simulationContainer.width-simulationContainer.x-1), random(1, height - 41));
    
    float dx = random(-2, 2);
    float dy = sqrt(4-(dx*dx));
    
    if(random(1) < .5) {
      dy = -dy;
    }
    
    velocity = new PVector(dx, dy);
    
    this.state = state;
    this.hasCollided = false;
  }
  
  public void initFrame() {
    hasCollided = false;
  }
  
  public boolean isActive() {
    return state.isActive();
  }
  
  public void move() {
    if(!isolated) {
      position.x+=velocity.x;
      position.y+=velocity.y;
    }
    if (simulationContainer.isOnBoundaryX(position.x)) {
      velocity.x *= -1;
    }
    if (simulationContainer.isOnBoundaryY(position.y)) {
      velocity.y *= -1;
    }
    
    if(state == State.INFECTED) {
      frameCountSinceSick++;
    }
    
    if (state == State.INFECTED && frameCountSinceSick >= sicknessLength) {
      float chance = random(100);
      if (chance > recoveryChance) {
        die();
      } else {
        recover();
      }
    }
  }
  
  public void collide(Blob blob) {
    if(!hasCollided) {
      if (blob.isolated) {
        this.velocity.x *=-1;
        this.velocity.y *=-1;
      } else if (this.isolated) {
        blob.velocity.x *=-1;
        blob.velocity.y *=-1;
      } else {
        PVector tempVelocity = new PVector(blob.velocity.x,blob.velocity.y);
        blob.velocity = new PVector(this.velocity.x,this.velocity.y);
        this.velocity = tempVelocity;
      }
      
      float chance = random(100);
      
      if (blob.getState() == State.INFECTED && this.getState() == State.HEALTHY) {
        if(chance < infectionChance) {
          this.infect();
        }
      }
      if(this.getState() == State.INFECTED && blob.getState() == State.HEALTHY) {
        if(chance < infectionChance) {
          blob.infect();
        }
      }
      
      blob.hasCollided = true;
      this.hasCollided = true;
    }
  }

  
  public PVector getVelocity() {
    return velocity;
  }
  
  public void infect() {
    this.state = State.INFECTED;
    infectedCount++;
    healthyCount--;
  }
  
  public void recover() {
    this.state = State.RECOVERED;
    infectedCount--;
    recoveredCount++;
  }
  
  public void die() {
    this.state = State.DEAD;
    infectedCount--;
    deadCount++;
  }
  
  public State getState(){return state;}

  public void isolate() {
    this.isolated = true;
    this.velocity = new PVector(0,0);
  }
}
