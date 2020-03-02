/*
const int colortex0Format = RGBA32F;
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;

const bool colortex2Clear = false;


*/

//Composite0
//todo

//Composite1.
//todo

//Composite2. Tune these for performance
#define MAX_RAY_STEPS           30
#define RAY_STEP_LENGTH         0.1
#define RAY_DEPTH_BIAS          0.05
#define RAY_GROWTH              1.05
#define NUM_RAYS                1  // [1 2 4 8 16 32]
#define NUM_BOUNCES             2

//Composite3
//todo

//Composite4
//todo

//Shadow
const int shadowMapResolution = 2048;  // [1024 2048 3072 4096 8192]

#define SHADOW_MAP_BIAS 0.80           // [0.00 0.60 0.70 0.80 0.85 0.90]
