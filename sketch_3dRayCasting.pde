void setup(){
  size(1024, 512);
  //size(300, 300);
  r = new Ray(new PVector(0, 0, 0), new PVector(0, 0, 0));
  
  tris = triStrip(new PVector[]{
    new PVector(-1, -5, -1),
    new PVector(-1, -5,  1),
    new PVector(10, -5, -1),
    new PVector(10, -5,  1),
    new PVector(10,  5, -1),
    new PVector(10,  5,  1),
    new PVector(-1,  5, -1),
    new PVector(-1,  5,  1),
    new PVector(-1, -5, -1),
    new PVector(-1, -5,  1)
  });
  
  tris = concat(tris, triStrip(new PVector[]{
    new PVector(-1, -5, -1),
    new PVector(10, -5, -1),
    new PVector(-1,  5, -1),
    new PVector(10,  5, -1)
  }));
  
  tris = concat(tris, triStrip(new PVector[]{
    new PVector(-1, -5,  1),
    new PVector(10, -5,  1),
    new PVector(-1,  5,  1),
    new PVector(10,  5,  1)
  }));
  
  tris = concat(tris, triStrip(new PVector[]{
    new PVector(5, -5, -1),
    new PVector(5, -5,  1),
    new PVector(3, -2, -1),
    new PVector(3, -1,  1),
    new PVector(10, 2, -1),
    new PVector(10, 2,  1),
  }));
  
  tris = concat(tris, triStrip(new PVector[]{
    new PVector(3, -1, -0.5),
    new PVector(3, -1,  0.5),
    new PVector(3,  1, -0.5),
    new PVector(3,  1,  0.5)
  }));
  
  //tris = concat(tris, triStrip(new PVector[]{
  //  new PVector(2, -1, -0.5),
  //  new PVector(2,  1, -0.5),
  //  new PVector(2,  1,  0.5),
  //}));
  
  cam = new Camera(new PVector(0, 0, 0), 110);
  
  _3dWindowSize = new PVector(2 * tan(radians(cam.FOV) / 2), 0);
  _3dWindowSize.y = height * _3dWindowSize.x / width;
  
  input = new boolean[]{false, false, false, false};
  
  lightPos = new PVector(0, 0, 0);
  lightOffset = new PVector(0.5, 0, 0.5);
}

Ray r;
Tri tris[];

int deRes = 2;

PVector _3dWindowSize;
Camera cam;
color wallCol = color(255, 255, 255);
color voidCol = color(10, 10, 10);

boolean[] input;

int forward = 0;
int backward = 1;
int left = 2;
int right = 3;

PVector lightPos;
PVector lightOffset;

void draw(){
  background(voidCol);
  
  cam.yaw = map(mouseX, 0, width, -180, 180);
  cam.pitch = map(mouseY, 0, height, -90, 90);
  
  r.p = cam.pos;
  
  PVector tl = new PVector(1, -_3dWindowSize.x / 2,  _3dWindowSize.y / 2);
  PVector tr = new PVector(1,  _3dWindowSize.x / 2,  _3dWindowSize.y / 2);
  PVector bl = new PVector(1, -_3dWindowSize.x / 2, -_3dWindowSize.y / 2);
  PVector br = new PVector(1,  _3dWindowSize.x / 2, -_3dWindowSize.y / 2);
  
  tl = rotate(tl, radians(cam.yaw), radians(cam.pitch), radians(cam.roll));
  tr = rotate(tr, radians(cam.yaw), radians(cam.pitch), radians(cam.roll));
  bl = rotate(bl, radians(cam.yaw), radians(cam.pitch), radians(cam.roll));
  br = rotate(br, radians(cam.yaw), radians(cam.pitch), radians(cam.roll));
  
  lightOffset.x = 1.5 + cos(radians(frameCount * 10));
  lightOffset.y = 1 + sin(radians(frameCount * 10));
  
  lightPos = vecadd(new PVector(0, 0, 0), lightOffset);
  
  noStroke();
  
  if(deRes == 1){
    loadPixels();
  }
  for(int x = 0; x < width; x += deRes){
    for(int y = 0; y < height; y += deRes){
      PVector p = null;
      Tri T = null;
      r.setDir(lerpVec(lerpVec(tl, tr, (float)x / (float)width), lerpVec(bl, br, (float)x / (float)width), (float)y / (float)height));
      float shortestD = -1;
      for(Tri t : tris){
        PVector pt = r.castOn(t);
        if(pt != null){
          float rayDist = dist(r.p.x, r.p.y, r.p.z, pt.x, pt.y, pt.z);
          if(shortestD < 0 || rayDist < shortestD){
            shortestD = rayDist;
            p = new PVector(pt.x, pt.y, pt.z);
            T = t;
          }
        }
      }
      if(p != null && T != null){
        r.p = p;
        r.setDir(vecsub(lightPos, p));
        float lightDist = vecsub(lightPos, p).mag();
        float pointD = -1;
        for(Tri t : tris){
          if(t != T){
            PVector pt = r.castOn(t);
            if(pt != null){
              float rayDist = vecsub(r.p, pt).mag();
              if(pointD < 0 || rayDist < pointD){
                pointD = rayDist;
              }
            }
          }
        }
        if(pointD < 0 || pointD > lightDist){
          if(deRes == 1){
            pixels[x + y * width] = lerpColor(voidCol, wallCol, abs(dotProd(r.r, T.getNorm())) / pow(lightDist / 2 + 1, 2));
          } else {
            fill(lerpColor(voidCol, wallCol, abs(dotProd(r.r, T.getNorm())) / pow(lightDist / 2 + 1, 2)));
            rect(x, y, deRes, deRes);
          }
        }
      }
      r.p = new PVector(cam.pos.x, cam.pos.y, cam.pos.z);
    }
  }
  if(deRes == 1){
    updatePixels();
  }
  
  fill(255);
  text(frameRate, 0, 10);
  
  PVector vel = new PVector();
  if(input[forward]){
    vel.add(new PVector(1, 0, 0));
  }
  if(input[backward]){
    vel.add(new PVector(-1, 0, 0));
  }
  if(input[left]){
    vel.add(new PVector(0, -1, 0));
  }
  if(input[right]){
    vel.add(new PVector(0, 1, 0));
  }
  if(dist(0, 0, vel.x, vel.y) != 0){
    vel = rotate(vel, radians(cam.yaw), 0, 0);
    vel = vecscale(vel, 0.1 / dist(0, 0, vel.x, vel.y));
    cam.pos.add(vel);
  }
}

void keyPressed(){
  if(key == 'w'){
    input[forward] = true;
  }
  if(key == 'a'){
    input[left] = true;
  }
  if(key == 's'){
    input[backward] = true;
  }
  if(key == 'd'){
    input[right] = true;
  }
}

void keyReleased(){
  if(key == 'w'){
    input[forward] = false;
  }
  if(key == 'a'){
    input[left] = false;
  }
  if(key == 's'){
    input[backward] = false;
  }
  if(key == 'd'){
    input[right] = false;
  }
}

void mousePressed(){
  lightPos = new PVector(cam.pos.x, cam.pos.y, cam.pos.z);
}

class Camera{
  PVector pos;
  float roll, pitch, yaw, FOV;
  
  Camera(PVector pos_, float FOV_){
    pos = pos_;
    pitch = 0;
    yaw = 0;
    roll = 0;
    FOV = FOV_;
  }
}

PVector lerpVec(PVector a, PVector b, float l){
  return vecadd(a, vecscale(vecsub(b, a), l));
}

class Tri{
  PVector a, b, c;
  
  Tri(PVector a_, PVector b_, PVector c_){
    a = a_;
    b = b_;
    c = c_;
  }
  
  PVector getNorm(){
    return crossProd(vecsub(b, a), vecsub(c, a)).normalize();
  }
}

class Ray{
  PVector p, r;
  float rayDist;
  
  Ray(PVector p_, PVector r_){
    p = p_;
    r = r_;
    rayDist = -1;
  }
  
  PVector castOn(Tri t){
    PVector n = t.getNorm();
    rayDist = dotProd(vecsub(t.a, p), n) / dotProd(r, n);
    if(rayDist < 0){
      return null;
    }
    PVector pt = vecadd(p, vecscale(r, rayDist));
    if(pointInTri(pt, t)){
      return pt;
    }
    rayDist = -1;
    return null;
  }
  
  void setDir(PVector dir){
    r = dir.normalize();
  }
}

boolean pointInTri(PVector p, Tri t){
  PVector a = t.a;
  PVector b = t.b;
  PVector c = t.c;
  PVector n = crossProd(vecsub(c, a), vecsub(b, a));
  PVector r = crossProd(vecsub(b, a), n);
  float s = dotProd(vecsub(p, a), r);
  if(s >= 0){
    r = crossProd(vecsub(c, b), n);
    s = dotProd(vecsub(p, b), r);
    if(s >= 0){
      r = crossProd(vecsub(a, c), n);
      s = dotProd(vecsub(p, c), r);
      if(s >= 0){
        return true;
      }
    }
  }
  return false;
}

Tri[] triStrip(PVector[] points){
  if(points.length < 3){
    return null;
  }
  Tri[] output = new Tri[points.length - 2];
  for(int i = 0; i < output.length; i++){
    output[i] = new Tri(points[i], points[i + 1], points[i + 2]);
  }
  return output;
}

Tri[] concat(Tri[] a, Tri[] b){
  Tri[] out = new Tri[a.length + b.length];
  for(int i = 0; i < a.length; i++){
    out[i] = a[i];
  }
  for(int i = 0; i < b.length; i++){
    out[a.length + i] = b[i];
  }
  return out;
}

PVector rotate(PVector p, float yaw, float pitch, float roll){
  Matrix out = matFromVec(p);
  Matrix M = new Matrix(new float[][]{{1,          0,          0},
                                      {0,  cos(roll), -sin(roll)},
                                      {0,  sin(roll),  cos(roll)}});
  out = M.cross(out);
  M = new Matrix(new float[][]{{ cos(pitch),  0, sin(pitch)},
                               {          0,  1,          0},
                               {-sin(pitch),  0, cos(pitch)}});
  out = M.cross(out);
  M = new Matrix(new float[][]{{cos(yaw), -sin(yaw), 0},
                               {sin(yaw),  cos(yaw), 0},
                               {0,         0,        1}});
  return vecFromMat(M.cross(out));
}

class Matrix{
  float[][] data;
  int w, h;
  
  Matrix(float[][] data_){
    data = data_;
    h = data.length;
    w = data[0].length;
  }
  
  Matrix cross(Matrix m){
    //|a11 a21 a31|   |b11 b21 b31|   |a11b11+a21b12+a31b13 a11b21+a21b22+a31b23 a11b31+a21b32+a31b33|
    //|a12 a22 a32| x |b12 b22 b32| = |a12b11+a22b12+a32b13 a12b21+a22b22+a32b23 a12b31+a22b32+a32b33|
    //|a13 a23 a33|   |b13 b23 b33|   |a13b11+a23b12+a33b13 a13b21+a23b22+a33b23 a13b31+a23b32+a33b33|
    
    //|a11 a21 a31|   |b11 b21|   |a11b11+a21b12+a31b13 a11b21+a21b22+a31b23|
    //|a12 a22 a32| x |b12 b22| = |a12b11+a22b12+a32b13 a12b21+a22b22+a32b23|
    //|a13 a23 a33|   |b13 b23|   |a13b11+a23b12+a33b13 a13b21+a23b22+a33b23|
    
    //|a11 a21 a31|   |b11 b21|   |a11b11+a21b12+a31b13 a11b21+a21b22+a31b23|
    //|a12 a22 a32| x |b12 b22| = |a12b11+a22b12+a32b13 a12b21+a22b22+a32b23|
    //                |b13 b23|
    
    if(w == m.h){
      Matrix out = new Matrix(new float[h][m.w]);
      for(int y = 0; y < out.h; y++){
        for(int x = 0; x < out.w; x++){
          float value = 0;
          for(int i = 0; i < w; i++){
            value += data[y][i] * m.data[i][x];
          }
          out.data[y][x] = value;
        }
      }
      return out;
    }
    return null;
  }
  
  void show(){
    for(int y = 0; y < h; y++){
      for(int x = 0; x < w; x++){
        print(data[y][x] + " ");
      }
      println();
    }
  }
}

Matrix matFromVec(PVector p){
  return new Matrix(new float[][]{{p.x}, {p.y}, {p.z}});
}

PVector vecFromMat(Matrix m){
  if(m.w == 1){
    if(m.h == 2){
      return new PVector(m.data[0][0], m.data[1][0]);
    }
    if(m.h == 3){
      return new PVector(m.data[0][0], m.data[1][0], m.data[2][0]);
    }
  }
  if(m.h == 1){
    if(m.w == 2){
      return new PVector(m.data[0][0], m.data[0][1]);
    }
    if(m.w == 3){
      return new PVector(m.data[0][0], m.data[0][1], m.data[0][2]);
    }
  }
  return null;
}

PVector vecadd(PVector a, PVector b){
  return new PVector(a.x + b.x, a.y + b.y, a.z + b.z);
}

PVector vecscale(PVector a, float l){
  return new PVector(a.x * l, a.y * l, a.z * l);
}

PVector vecsub(PVector a, PVector b){
  return new PVector(a.x - b.x, a.y - b.y, a.z - b.z);
}

float dotProd(PVector a, PVector b){
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

PVector crossProd(PVector a, PVector b){
  return new PVector(a.y * b.z - a.z * b.y, b.x * a.z - a.x * b.z, a.x * b.y - b.x * a.y);
}
