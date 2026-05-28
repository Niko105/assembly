typedef struct {
    int x; // x coordinate
    int y; // y coordinate
} Point;
typedef struct {
    Point origin;
    int width;  // natural number, width of the rect
    int height; // natural number, height of the rect
    int colour; // number whose bytes are AARRGGBB
} Rect;
int area(Rect r) { return r.width * r.height; }
Point center(Rect r) { return r.origin; }
void setPos(Rect *r, Point p) { r->origin = p; }
//-----//
int main() {
    Point a = {4, 3};      // create a point
    Rect b = {a, 4, 2, 0}; // create a rect
    Point c = {2, 3};      // create another point
    area(b);   // calculate the area and don't care about the return cause it's
               // in assembly and it'd be annoying
    center(b); // calculate the center of the rect (extract the origin)
    setPos(&b, c); // set the position of Rect a to Point b
}
