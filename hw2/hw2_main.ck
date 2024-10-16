/*
    Homework 2

    Birds fly around a nice green field
    So much isn't done yet :(

    Input Modes:
        0 - DAC (default)
        1 - SndBuf
        2 - Noise

    To set the mode, run:
        `chuck hw2_main.ck:<mode number>`
        e.g. `chuck hw2_main.ck:1`

    TODO: interpolate most animations (can I pass functions around...?)
          also normalize waves
          add bloom to sun and moon


    More TODO: for office hours
        - scale of flight path when negative Z
            - use screenCoordToWorldPos

    TODO: IDEAS to Implement:
        - Big birds are bass (LPF), medium birds are middle, small birds are highs (HPF)
        - Take DFT per bird, so when it "sings" the spectrum flies out of its mouth (maybe at some sampling period)
            - have the spectrum fly out and shrink (scale down) to fade away
        - Daylight is more consenent, nightime is more disonant / minor sounds
        - add interpolation to waves
*/

// Window Setup
GWindow.title("Sound of Flight");
GWindow.fullscreen();

// Camera
global GCamera mainCam;
GG.scene().camera() @=> mainCam;
mainCam.posZ(8.0);

// Lighting
GG.scene().light() @=> GLight sceneLight;

// Handle audio source
0 => int AUDIO_MODE;
if(me.args()) {
    me.arg(0).toInt() => AUDIO_MODE;
}


// Quick and dirty read from buffer and play sound for milestone
// TODO: get rid of this after milestone
me.dir() + "sunday.wav" => string filename;
SndBuf buf(filename) => dac;
0 => buf.gain;


fun void playFile() {
    if (AUDIO_MODE != 1) return;

    TriOsc rateMod(0.01) => blackhole;
    0.5 => buf.gain;
    0 => buf.pos;
    1. => buf.rate;

    while (true) {
        Std.scalef(rateMod.last(), -1., 1., 0.08, 3.) => float rate;
        rate => buf.rate;
        1::ms => now;
    }
}

// Noise generation
Noise noiz => BPF noizefilter => Gain noizeGain;
fun void playNoise() {
    if (AUDIO_MODE != 2) return;

    noizeGain => dac;
    TriOsc sweep(0.2) => blackhole;

    noizefilter.set(5000, 0.80);
    0.3 => noizeGain.gain;

    while (true) {
        Std.scalef(sweep.last(), -1., 1., 60, 8000) => float newFreq;
        newFreq => noizefilter.freq;
        1::ms => now;
    }
}

// TODO: Bloom handling
// GG.renderPass() --> BloomPass bloom_pass --> GG.outputPass();
// bloom_pass.input(GG.renderPass().colorOutput());
// GG.outputPass().input(bloom_pass.colorOutput());
// bloom_pass.intensity(0.9);
// bloom_pass.radius(0.7);
// bloom_pass.levels(9);


// Helper Functions
fun void scaleVectorArray(vec2 v[], float xScale, float yScale, float xShift, float yShift) {
    for (int idx; idx < v.size(); idx++) {
        v[idx] => vec2 currVec;
        @((currVec.x + xShift) * xScale, (currVec.y + yShift)* yScale) => v[idx];
    }
}


// Classes
class EnvelopeFollower {
    float prevStrength;
    float currStrength;
    float slewUp;
    float slewDown;
    float threshold;

    Gain edGain;
    OnePole edFilter;

    fun @construct() {
        // Envelope detection
        if (AUDIO_MODE == 0) {
            adc => edGain;
            adc => edGain;
        } else if (AUDIO_MODE == 1) {
            buf => edGain;
            buf => edGain;
        } else if (AUDIO_MODE == 2) {
            noizeGain => edGain;
            noizeGain => edGain;
        }

        edGain => edFilter => blackhole;
        3 => edGain.op;
        0.999 => edFilter.pole;

        0.6 => slewUp;
        0.05 => slewDown;
        0.8 => threshold;
    }

    fun void follow() {
        while (true) {
            GG.nextFrame() => now;
            // get current signal strength
            Math.pow(edFilter.last(), threshold) => currStrength;

            // interpolate
            if (prevStrength < currStrength)
                prevStrength + (currStrength - prevStrength) * slewUp => currStrength;
            else
                prevStrength + (currStrength - prevStrength) * slewDown => currStrength;

            // update previous value
            currStrength => prevStrength;
        }
    }

    fun float getCurrSignalStrength() {
        return currStrength;
    }
}


class AudioProcessing {
    /*
        Handles input audio processing
        Keeps track of time-domain `waveform` and frequency-domain `spectrum`
    */
    1024 => int WINDOW_SIZE;
    10 => float DISPLAY_WIDTH;
    64 => int HISTORY_SIZE;

    Flip accum;
    PoleZero dcblocker;
    FFT fft;

    // Samples + FFT
    float samples[0];
    complex response[0];
    vec2 prevWaveform[WINDOW_SIZE];
    vec2 waveform[WINDOW_SIZE];
    vec2 spectrum[WINDOW_SIZE];

    // Keep track of spectrum history
    vec2 spectrumHistory[HISTORY_SIZE][WINDOW_SIZE];
    0 => int historyPointer;

    float window[];

    fun @construct() {
        // Waveform and spectrum analysis objects
        if (AUDIO_MODE == 0) {
            adc => accum;
            adc => dcblocker;
        } else if (AUDIO_MODE == 1) {
            buf => accum;
            buf => dcblocker;
        } else if (AUDIO_MODE == 2) {
            noizeGain => accum;
            noizeGain => dcblocker;
        }

        accum => blackhole;
        dcblocker => fft => blackhole;

        // adjust DC blocking band
        .95 => dcblocker.blockZero;

        // set size of flip
        WINDOW_SIZE => accum.size;
        // set window type and size
        Windowing.hann(WINDOW_SIZE) => fft.window;
        // set FFT size (will automatically zero pad)
        WINDOW_SIZE*2 => fft.size;
        // get a reference for our window for visual tapering of the waveform
        Windowing.hann(WINDOW_SIZE) @=> window;

    }

    fun void map2waveform() {
        if( samples.size() != waveform.size() ) {
            <<< "size mismatch in map2waveform()", "" >>>;
            return;
        }

        // mapping to xyz coordinate
        for (int i; i < samples.size(); i++) {
            // space evenly in X
            -DISPLAY_WIDTH/2 + DISPLAY_WIDTH/WINDOW_SIZE*i => waveform[i].x;
            // map y, using window function to taper the ends
            samples[i] * 2 * window[i] => waveform[i].y;
        }
    }

    fun void map2spectrum() {
        if( response.size() != spectrum.size() ) {
            <<< "size mismatch in map2spectrum()", "" >>>;
            return;
        }

        // mapping to xyz coordinate
        for (int i; i < response.size(); i++) {
            // space evenly in X
            -DISPLAY_WIDTH/2 + DISPLAY_WIDTH/WINDOW_SIZE*i => spectrum[i].x;
            // map frequency bin magnitide in Y
            25 * Math.sqrt( (response[i]$polar).mag ) => spectrum[i].y;
        }
    }

    fun vec2[] getInterpolatedWaveform(float slew) {
        vec2 interpWaveform[WINDOW_SIZE];

        for (int idx; idx < WINDOW_SIZE; idx++) {
            prevWaveform[idx] + slew * (waveform[idx] - prevWaveform[idx]) => interpWaveform[idx];
            waveform[idx] => prevWaveform[idx];
        }

        return interpWaveform;
    }

    fun void updateSpectrumHistory() {
        // Overwrite oldest spectrum entry with latest
        vec2 spectrumCopy[WINDOW_SIZE];
        for (int idx; idx < WINDOW_SIZE; idx++ ) {
            spectrum[idx] @=> vec2 currPos;
            @(currPos.x, currPos.y) => spectrumCopy[idx];
        }

        spectrumCopy @=> spectrumHistory[historyPointer];

        // Update pointer and wrap back around if needed
        historyPointer++;
        HISTORY_SIZE %=> historyPointer;
    }

    fun vec2[] getLastNthSpectrum(int n) {
        /* Returns the last Nth spectrogram
           e.g. 0 returns the most recent, 1 returns the second most recent
           2 returns the third most recent, and so on
        */

        if (n >= HISTORY_SIZE) {
            <<< "ERROR | Requested Spectrum: ", n, ", History Size: ", HISTORY_SIZE>>>;
            vec2 fail[];
            return fail;
        }
        (historyPointer - n) % HISTORY_SIZE => int spectrumIdx;

        vec2 spectrumCopy[WINDOW_SIZE];
        spectrumHistory[spectrumIdx] @=> vec2 currSpectrum[];

        for (int idx; idx < WINDOW_SIZE; idx++ ) {
            currSpectrum[idx] @=> vec2 currPos;
            @(currPos.x, currPos.y) => spectrumCopy[idx];
        }

        return spectrumCopy;
    }

    fun void processInputAudio() {
        while( true ) {
            // upchuck to process accum
            accum.upchuck();
            // get the last window size samples (waveform)
            accum.output( samples );
            // upchuck to take FFT, get magnitude response
            fft.upchuck();
            // get spectrum (as complex values)
            fft.spectrum( response );
            // jump by samples
            WINDOW_SIZE::samp/2 => now;
        }
    }

    fun void processWaveformGraphics() {
        while( true ) {
            // map to interleaved format
            map2waveform();
            // map to spectrum display
            map2spectrum();
            // store latest spectrum in history
            updateSpectrumHistory();
            // next graphics frame
            GG.nextFrame() => now;
        }
    }
}


class Sun extends GGen {
    32 => int numRays;
    vec3 anchorPoint;

    GCircle sun;
    GLines rays[numRays];

    fun @construct(vec3 sunAnchorPoint) {
        sunAnchorPoint => anchorPoint;
        anchorPoint => sun.pos;
        Color.YELLOW => sun.color;

        // setup to graphics
        sun --> this;
        for (0 => int idx; idx < numRays; idx++) {
            rays[idx] @=> GLines ray;
            @(0., 0., 0.01) => ray.pos;
            0.12 => ray.scaX;
            0.5 => ray.width;
            Color.YELLOW => ray.color;
            idx * (Math.PI / 16) => ray.rotateZ;
            ray --> sun;
        }

        this --> GG.scene();

        // Set UI name
        this.name("Sun");
    }

    fun void move(float xDelta, float yDelta) {
        xDelta + anchorPoint.x => this.posX;
        yDelta + anchorPoint.y => this.posY;
    }

    fun void animateRays(vec2 waveform[]) {
        while (true) {
            // next graphics frame
            GG.nextFrame() => now;

            // Apply waveform to sun rays
            for (GLines ray : rays) {
                ray.positions( waveform );
            }
        }
    }
}


class Moon extends GGen {
    // TODO: Sun and Moon should inherit from a CelestialBody class, lots of overlap
    // ADD bloom to moon and sun
    vec3 anchorPoint;
    16 => float intensity;

    GCircle moon;

    fun @construct(vec3 moonAnchorPoint) {
        moonAnchorPoint => anchorPoint;
        anchorPoint => moon.pos;
        Color.WHITE => moon.color;
        Color.WHITE => moon.specular;

        // Display in scene
        moon --> this --> GG.scene();

        // Set UI name
        this.name("Moon");
    }

    fun void glow(EnvelopeFollower ef) {
        while (true) {
            GG.nextFrame() => now;
            ef.getCurrSignalStrength() => float currStrength;
            // clip on low end
            currStrength * Color.WHITE * intensity => moon.color;
        }
    }

    fun void move(float xDelta, float yDelta) {
        xDelta + anchorPoint.x => this.posX;
        yDelta + anchorPoint.y => this.posY;
    }
}


class SkyBox {
    dur dayNightCyclePeriod;

    SinOsc dayNightCycleLFO => blackhole;
    Phasor dayNightCyclePhase => blackhole;

    @(0., -1.5, -2.) => vec3 skyAnchor;
    @(0.4, 0.749, 1.) => vec3 skyColor;

    Sun sun(skyAnchor);
    Moon moon(skyAnchor);

    float lightRotateAmount;

    fun @construct(dur period) {
        period => dayNightCyclePeriod;
        (2 * Math.PI) / ((period / 2) / ms) => lightRotateAmount;
        dayNightCyclePeriod => dayNightCycleLFO.period => dayNightCyclePhase.period;
        skyColor => GG.scene().backgroundColor;
    }

    fun void dayNightCycle() {
        // spork ~ moon.glow();

        while (true) {
            // Update skybox
            Std.scalef(dayNightCycleLFO.last(), -1., 1., 0.02, 1.) => float skyColorMult;
            skyColor * skyColorMult => GG.scene().backgroundColor;

            // Move sun and moon
            Std.scalef(dayNightCyclePhase.last(), 0., 1., 0., 2. * Math.PI) => float angle;
            sun.move(
                (Math.cos(angle) * 5.),
                (Math.sin(angle) * 5.)
            );

            moon.move(
                (Math.cos(angle + Math.PI) * 5.),
                (Math.sin(angle + Math.PI) * 5.)
            );

            // change lighting
            Std.scalef(dayNightCycleLFO.last(), -1., 1., 0.1, 1.) => float intensity;
            intensity => sceneLight.intensity;
            // lightRotateAmount => sceneLight.rotateZ;

            1::ms => now;
        }
    }
}


class Grass extends GGen {
    // ADD interpolation to grass waving
    40 => int numWaves;
    [-6.3, -4.5, -2.7, -0.9, 0.9, 2.7, 4.5, 6.3] @=> float xSpacing[];
    [1.5, 0.75, 0., -0.75, -1.5] @=> float zSpacing[];
    int numColumns;
    int numRows;

    GCube field;
    GLines grassWaves[numWaves];

    fun @construct() {
        // Set field attributes
        -3 => this.posY;
        @(15., 1., 4.) => field.sca;
        Color.DARKGREEN => field.color;

        0 => int grassMult;
        0. => float rotation;
        xSpacing.size() => numColumns;
        zSpacing.size() => numRows;

        for (0 => int column; column < numColumns; column++) {
            for (0 => int row; row < numRows; row++) {
                grassWaves[(numRows * column) + row] @=> GLines grassWave;

                // Position grass on field in interesting ways
                xSpacing[column] => grassWave.posX;
                0.5 => grassWave.posY;
                zSpacing[row] => grassWave.posZ;

                // Rotation
                if (column % 2 == 0) {
                    Math.PI => grassWave.rotateY;;
                }

                // Width and scale
                0.05 => grassWave.width;
                0.18 => grassWave.scaX;
                0.6 => grassWave.scaY;

                ((numRows - row) * 0.25) + 0.25 => float intensity;
                Color.DARKGREEN * intensity => grassWave.color;

                // Name + connection
                "(" + column + ", " + row + ")" => grassWave.name;
                grassWave --> this;
            }
            grassMult + 1 => grassMult;
        }

        field --> this --> GG.scene();

        // Set UI name
        this.name("Grass");
    }

    fun void animateGrass(AudioProcessing dsp) {
    // fun void animateGrass(vec2 spectrum[]) {
        while (true) {
            GG.nextFrame() => now;

            for (0 => int row; row < numRows; row++) {
                for (0 => int column; column < numColumns; column++) {
                    grassWaves[(numRows * column) + row] @=> GLines grassWave;

                    dsp.getLastNthSpectrum(row * 2) => grassWave.positions;
                }
            }
        }
    }
}


class Bird extends GGen {
    /*
    TODO: Some ideas

    Use the spectral analysis as "bird feathers"
    Maybe interpolate them a bit so they "blow in the wind" but softly

    Have birds land on the wire and "sing" along with the music
    */

    // graphics objects
    GCube body;
    GCube leftWing;
    GCube rightWing;
    GCube tailTop;
    GCube tailBottom;

    GCube head;
    GCube beakTop;
    GCube beakBottom;
    GCube eye;

    // animation variables
    int inFlight;
    int mouthMoving;
    float rotateAmount;

    // movement
    float moveSpeed;
    float shiftY;
    float shiftZ;
    vec2 path[];
    vec2 currPathGraphics[0];
    GLines pathGraphics;

    fun @construct(float flapPeriod, float moveSpeed, float shiftY, float shiftZ, vec2 movementPath[]) {
        // set instance variables
        1 => inFlight;
        1 => mouthMoving;
        (2 * Math.PI) / (flapPeriod * 1000) => rotateAmount;
        moveSpeed => this.moveSpeed;
        shiftY => this.shiftY;
        shiftZ => this.shiftZ;

        // Handle X movement
        movementPath[0].x => float startingX;
        this.calculateScaleFactor(startingX, shiftZ) * 1.3 => float scalingFactor;
        scaleVectorArray(movementPath, scalingFactor, 1., 0., shiftY);
        movementPath @=> path;

        // Colors
        Color.random() => vec3 birdColor;

        // Graphics rendering
        // Handle head
        @(0.65, 0.5, 0.8) => head.sca;
        @(0.4, 0.4, 0.) => head.pos;
        birdColor * 0.8 => head.color;

        // Handle eye
        @(0.25, 0.2, 1.1) => eye.sca;
        @(0.2, 0.1, 0.) => eye.pos;
        Color.WHITE * 5. => eye.color;

        // Handle beak
        @(0.6, 0.1, 0.5) => beakTop.sca;
        0.5 => beakTop.posX;
        @(0.5, 0.1, 0.5) => beakBottom.sca;
        @(0.45, -0.1, 0.) => beakBottom.pos;

        Color.BLACK => beakTop.color;
        Color.BLACK => beakBottom.color;

        // Handle body
        0.5 => body.scaY;
        birdColor => body.color;

        // Handle wing
        -0.5 => leftWing.posZ;
        0.5 => rightWing.posZ;
        @(0.5, 0.2, 1.) => leftWing.sca;
        @(0.5, 0.2, 1.) => rightWing.sca;
        birdColor * 1.2 => rightWing.color;
        birdColor * 1.2 => leftWing.color;

        // Handle tail
        @(-0.5, 0., 0.) => tailTop.pos;
        @(0.7, 0.2, 0.6) => tailTop.sca;
        -Math.PI / 4 => tailTop.rotZ;
        birdColor * 1.2 => tailTop.color;

        @(-0.5, 0., 0.) => tailBottom.pos;
        @(0.7, 0.2, 0.6) => tailBottom.sca;
        Math.PI / 4 => tailBottom.rotZ;
        birdColor * 1.2 => tailBottom.color;

        // Shift in Z direction
        shiftZ => this.posZ;

        // draw movement path
        birdColor => pathGraphics.color;
        Std.scalef(this.posZ(), -6, 2, 0.005, 0.04) => float linesWidth;
        linesWidth => pathGraphics.width;

        shiftZ => pathGraphics.posZ;
        pathGraphics --> GG.scene();

        // Name the objects for easy UI debugging
        "Head" => head.name;
        "Body" => body.name;
        "Eye" => eye.name;
        "Left Wing" => leftWing.name;
        "Right Wing" => rightWing.name;
        "Tail Top" => tailTop.name;
        "Tail Bottom" => tailBottom.name;
        "Beak Top" => beakTop.name;
        "Beak Bottom" => beakBottom.name;
        "Bird" => this.name;

        // Create the connections
        rightWing --> body;
        leftWing --> body;
        tailBottom --> body;
        tailTop --> body --> this;
        eye --> head;
        beakBottom --> head;
        beakTop --> head --> this;
        this --> GG.scene();
    }

    fun float calculateScaleFactor(float startingX, float shiftZ) {
        @(0., 0.) => vec2 screenPos;
        mainCam.screenCoordToWorldPos(screenPos, mainCam.posZ() - shiftZ) @=> vec3 worldPos;
        worldPos.x => float newX;
        return newX / startingX;
    }

    fun drawPath(vec2 currPathGraphics[], int idx, float shiftY) {
        @(path[idx].x, path[idx].y + shiftY) => vec2 pos;
        currPathGraphics << pos;

        currPathGraphics => pathGraphics.positions;
    }

    fun removePathSegment(vec2 currPathGraphics[]) {
        currPathGraphics.popFront();
        currPathGraphics => pathGraphics.positions;
    }

    fun removePath(vec2 currPathGraphics[], dur segmentRemovalDur) {
        currPathGraphics.size() => int end;
        for (int idx; idx < end; idx++) {
            this.removePathSegment(currPathGraphics);
            segmentRemovalDur => now;
        }
        me.exit();
    }

    fun void moveForward(int idx, float yStepSize) {
        path[idx] => vec2 pos;
        if (idx == 0 || idx >= path.size() - 1) {
            pos.x => this.posX;
            pos.y => this.posY;
            1::ms => now;
        } else {
            path[idx + 1] => vec2 nextPos;

            (nextPos.x - pos.x) / moveSpeed => float stepX;
            ((nextPos.y - pos.y) + yStepSize) / moveSpeed => float stepY;

            while (this.posX() < nextPos.x) {
                this.posX() + stepX => this.posX;
                this.posY() + stepY => this.posY;
                1::ms => now;
            }
        }
    }

    fun void animateWing() {
        TriOsc wingAnimator(1.) => blackhole;
        while (true) {
            if (inFlight == 1) {
                Std.scalef(wingAnimator.last(), -1., 1., -Math.PI / 4, Math.PI / 4) => float rotation;
                -rotation => leftWing.rotX;
                rotation => rightWing.rotX;
            }
            GG.nextFrame() => now;
        }
    }

    fun void animateMouth() {
        TriOsc mouthAnimator(1.) => blackhole;
        while (true) {
            if (mouthMoving == 1) {
                Std.scalef(mouthAnimator.last(), -1., 1., 0., Math.PI / 4) => float rotation;
                rotation => beakTop.rotZ;
                -rotation => beakBottom.rotZ;
            }
            GG.nextFrame() => now;
        }
    }
}


class FlyingBird extends Bird {
    fun @construct(float flapPeriod, float moveSpeed, float shiftY, float shiftZ, vec2 movementPath[]) {
        Bird(flapPeriod, moveSpeed, shiftY, shiftZ, movementPath);
        "Flying Bird" => this.name;
    }

    fun void animate() {
        spork ~ animateWing();
        spork ~ animateMouth();
        spork ~ animateMovement();
    }

    fun void animateMovement() {
        // Move bird across the screen
        for (int idx; idx < path.size(); idx++) {
            this.moveForward(idx, 0.);
            this.drawPath(currPathGraphics, idx, 0);
        }

        // Fade out path
        1::ms => dur segmentRemovalDur;
        spork ~ removePath(currPathGraphics, segmentRemovalDur);
        me.yield();
        segmentRemovalDur * currPathGraphics.size() => now;

        // Remove the bird and path graphics from the scene
        pathGraphics --< GG.scene();
        this --< GG.scene();

        me.exit();
    }
}


class SingingBird extends Bird {
    fun @construct(float flapPeriod, float moveSpeed, float shiftY, float shiftZ, vec2 movementPath[]) {
        Bird(flapPeriod, moveSpeed, shiftY, shiftZ, movementPath);
        "Singing Bird" => this.name;
    }

    fun void animate(int startLanding, int endLanding, int endTakeoff) {
        spork ~ animateWing();
        spork ~ animateMouth();
        spork ~ animateMovement(startLanding, endLanding, endTakeoff);
    }

    fun float calculateRotation(int startIdx, int stopIdx, float yStepSize, float numSteps) {
        path[stopIdx].x - path[startIdx].x => float X;
        (path[stopIdx].y + (yStepSize * (numSteps - 1))) - path[startIdx].y => float Y;
        Math.atan2(Y, X) => float angle;
        return angle;
    }

    fun void animateRotation(float startAngle, float stopAngle) {
        startAngle => float currAngle;
        100. => float numSteps;
        ((stopAngle - startAngle) / numSteps) => float stepSize;

        for (int currStep; currStep < numSteps; currStep++) {
            currAngle + stepSize => currAngle;
            currAngle => this.rotZ;
            1::ms => now;
        }

        me.exit();
    }

    fun void animateMovement(int startLanding, int endLanding, int endTakeoff) {
        startLanding => int startIdx;
        endLanding => int stopIdx;

        // Handle straight forward movement
        for (int idx; idx < startIdx; idx++) {
            this.moveForward(idx, 0.);
            this.drawPath(currPathGraphics, idx, 0);
        }

        // Calculate variables needed for landing
        this.posY() => float startY;
        -0.51 => float yTarget;
        stopIdx - startIdx => float numSteps;
        yTarget - startY => float yDistance;
        yDistance / numSteps => float yStepSize;

        // Calculate landing rotation
        this.calculateRotation(startIdx, stopIdx, yStepSize, numSteps) => float stopAngle;
        spork ~ animateRotation(this.rotZ(), stopAngle);

        // Handle landing on the wire
        for (startIdx => int idx; idx < stopIdx; idx++) {
            this.moveForward(idx, yStepSize);
            this.drawPath(currPathGraphics, idx, ((idx - startIdx) * yStepSize));
        }

        // Reset rotation
        spork ~ animateRotation(this.rotZ(), 0.);

        // Snap to wire
        yTarget => this.posY;

        spork ~ removePath(currPathGraphics, 1::ms);

        // Waiting on the wire
        4::second => now;

        // Starting idx is current idx on the wire, update new stoping idx
        stopIdx => startIdx;
        endTakeoff => stopIdx;

        // recalculate variables needed for takeoff
        yTarget => startY;
        path[stopIdx].y => yTarget;
        stopIdx - startIdx => numSteps;
        yTarget - startY => yDistance;
        yDistance / numSteps => yStepSize;

        // Calculate takeoff rotation
        this.calculateRotation(startIdx, stopIdx, yStepSize, numSteps) => stopAngle;
        spork ~ animateRotation(this.rotZ(), stopAngle);

        // Taking off from the wire
        for (startIdx => int idx; idx < stopIdx; idx++) {
            this.moveForward(idx, yStepSize);
            this.drawPath(currPathGraphics, idx, (stopIdx - idx) * yStepSize * -1);
        }

        // Reset rotation
        spork ~ animateRotation(this.rotZ(), 0.);

        // Flying off the screen
        for (stopIdx => int idx; idx < path.size(); idx++) {
            this.moveForward(idx, 0.);
            this.drawPath(currPathGraphics, idx, 0);
        }

        // Fade out graphics path
        1::ms => dur segmentRemovalDur;
        spork ~ removePath(currPathGraphics, segmentRemovalDur);
        segmentRemovalDur * currPathGraphics.size() => now;

        // Remove the bird and path graphics from the scene
        pathGraphics --< GG.scene();
        this --< GG.scene();

        me.exit();
    }

    fun void moveOnWire() {

    }
}


class BirdGenerator {
    dur birdFrequency;
    dur startDelay;

    fun @construct(dur delay) {
        delay => startDelay;
        5::second => birdFrequency;
    }

    fun @construct(dur startDelay, dur birdFrequency) {
        startDelay => this.startDelay;
        birdFrequency => this.birdFrequency;
    }

    fun void addFlyindBird(AudioProcessing dsp) {
        startDelay => now;
        while (true) {

            Math.random2f(-2., 5.) => float shiftY;
            Math.random2f(-6., 2.) => float shiftZ;

            // create new bird
            dsp.getLastNthSpectrum(0) @=> vec2 spectrum[];
            FlyingBird bird(.5, 10., shiftY, shiftZ, spectrum);

            Math.random2f(0.2, 0.6) => float scaleAmt;
            @(scaleAmt, scaleAmt, scaleAmt) => bird.sca;

            // let it fly!
            bird.animate();
            birdFrequency => now;
        }
    }

    fun void addSingingBird(AudioProcessing dsp) {
        startDelay => now;
        while (true) {

            Math.random2f(-2., 5.) => float shiftY;

            // create new bird
            dsp.getLastNthSpectrum(0) @=> vec2 spectrum[];
            SingingBird bird(.5, 10., shiftY, 1., spectrum);

            Math.random2f(0.2, 0.6) => float scaleAmt;
            @(scaleAmt, scaleAmt, scaleAmt) => bird.sca;

            // let it fly!
            Math.random2(50, 200) => int startLanding;
            Math.random2(250, 550) => int endLanding;
            Math.random2(750, dsp.WINDOW_SIZE - 100) => int endTakeoff;

            bird.animate(startLanding, endLanding, endTakeoff);
            5::second => now;
        }

    }
}


class Pole extends GGen {
    GCube pole;

    fun @construct() {
        pole --> GG.scene();

        // scale
        pole.sca( @(0.1, 3., 0.2) );

        // color
        Color.BROWN => pole.color;
    }

    fun void setPos(vec3 pos) {
        pole.pos( pos );
    }
}


class TelephonePole extends GGen {
    Pole leftPole;
    Pole rightPole;
    GLines wire;

    fun @construct(vec3 pos, float poleOffset) {
        // Set wire params
        wire.width(.02);
        wire --> GG.scene();
        leftPole --> this;
        rightPole --> this;
        wire.pos( @(pos.x, -0.6, pos.z + 0.01) );
        0.8 => wire.scaX;

        // Set pos
        leftPole.setPos( @(pos.x - poleOffset, pos.y, pos.z) );
        rightPole.setPos( @(pos.x + poleOffset, pos.y, pos.z) );

        // names
        "Left Pole" => leftPole.name;
        "Right Pole" => rightPole.name;
        "Wire" => wire.name;
        "Telephone Pole" => this.name;
    }

    fun void wireMovement(vec2 waveform[]) {
        while (true) {
            // next graphics frame
            GG.nextFrame() => now;
            wire.positions( waveform );
        }
    }
}

// ************* //
// AUDIO CLASSES //
// ************* //
class BassOsc {

}

class LeadOsc {

}

// Instantiate objects
// ADC objects
AudioProcessing dsp();
EnvelopeFollower envFollower();

// Graphics objects
SkyBox sky(30::second);
Grass grass();
TelephonePole wires( @(0., -2., 1), 4);
wires --> GG.scene();

// Birds!
BirdGenerator birdGen(2::second, 3::second);

// Shred away
// Audio processing shreds
spork ~ dsp.processInputAudio();
spork ~ dsp.processWaveformGraphics();
spork ~ envFollower.follow();

// graphics shreds
spork ~ sky.dayNightCycle();
spork ~ wires.wireMovement(dsp.waveform);
spork ~ sky.sun.animateRays(dsp.waveform);
spork ~ grass.animateGrass(dsp);
spork ~ sky.moon.glow(envFollower);

// Bird movement shreds
spork ~ birdGen.addFlyindBird(dsp);
spork ~ birdGen.addSingingBird(dsp);

// Audio shreds
spork ~ playFile();
spork ~ playNoise();


while (true) {
    // main loop
    GG.nextFrame() => now;

    if (UI.begin("Tutorial")) {
        // show a UI display of the current scenegraph
        UI.scenegraph(GG.scene());
    }
    UI.end();
}
