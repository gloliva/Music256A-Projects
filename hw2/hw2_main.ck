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


    TODO: IDEAS to Implement:
        - Big birds are bass (LPF), medium birds are middle, small birds are highs (HPF)
        - Take DFT per bird, so when it "sings" the spectrum flies out of its mouth (maybe at some sampling period)
            - have the spectrum fly out and shrink (scale down) to fade away
        - Daylight is more consenent, nightime is more disonant / minor sounds
        - add interpolation to waves
        - Pan birds left and right depending on where they are on the wire
        - Use the spectral analysis as "bird feathers"
        - Maybe interpolate them a bit so they "blow in the wind" but softly
        - Have birds land on the wire and "sing" along with the music
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

// Global Tempo Variables
120. => float TEMPO;
(60. / TEMPO)::second => dur QUARTER_NOTE;

// Global audio
Gain MASTER[2] => dac;
Gain PROCESSING_GAIN;

// Handle audio source
0 => int AUDIO_MODE;
if(me.args()) {
    me.arg(0).toInt() => AUDIO_MODE;
}


// Play wind sound
me.dir() + "wind.wav" => string filename;
SndBuf buf(filename) => MASTER;
buf => PROCESSING_GAIN;
0.8 => buf.gain;
1. => buf.rate;
1 => buf.loop;


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
        @((currVec.x + xShift) * xScale, (currVec.y + yShift) * yScale) => v[idx];
    }
}


// ************************ //
// AUDIO PROCESSING CLASSES //
// ************************ //
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

    fun void chainFMOsc(FMOsc osc) {
        osc.main => edGain;
    }

    fun void chainDetuneOsc(DetuneOsc osc) {
        osc.main => edGain;
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
    vec2 interpWaveform[WINDOW_SIZE];
    vec2 spectrum[WINDOW_SIZE];

    // interpolation
    float slew;

    // Keep track of spectrum history
    vec2 spectrumHistory[HISTORY_SIZE][WINDOW_SIZE];
    0 => int historyPointer;

    float window[];

    fun @construct(Gain input) {
        // Waveform and spectrum analysis objects
        input => accum => blackhole;
        input => dcblocker => fft => blackhole;

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

        // interpolation
        1. => slew;
    }

    fun void setSlew(float slew) {
        slew => this.slew;
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

    fun void updateInterpolatedWaveform() {
        for (int idx; idx < WINDOW_SIZE; idx++) {
            this.waveform[idx] @=> vec2 currWave;

            this.prevWaveform[idx].x + (currWave.x - this.prevWaveform[idx].x) * slew => float interpX;
            this.prevWaveform[idx].y + (currWave.y - this.prevWaveform[idx].y) * slew => float interpY;

            interpX => interpWaveform[idx].x;
            interpY => interpWaveform[idx].y;

            currWave.x => this.prevWaveform[idx].x;
            currWave.y => this.prevWaveform[idx].y;
        }
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
            <<< "ERROR | Requested Spectrum: ", n, ", History Size: ", HISTORY_SIZE >>>;
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
            // interpolated waveform
            updateInterpolatedWaveform();
            // store latest spectrum in history
            updateSpectrumHistory();
            // next graphics frame
            GG.nextFrame() => now;
        }
    }
}


// **************** //
// GRAPHICS CLASSES //
// **************** //
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
    32 => float intensity;

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
            // currStrength * Color.WHITE * intensity => moon.color;
            Color.WHITE * intensity => moon.color;
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

            GG.nextFrame() => now;
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


class Pole extends GGen {
    GCube pole;

    fun @construct() {
        pole --> this;

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
    GCube leftCrossarm;
    GCube rightCrossarm;

    GLines backWire;
    GLines middleWire;
    GLines frontWire;

    fun @construct(vec3 pos, float poleOffset) {
        // Set wire params
        backWire.width(.02);
        middleWire.width(.02);
        frontWire.width(.02);

        backWire.pos( @(pos.x, -0.6, pos.z - 0.75) );
        middleWire.pos( @(pos.x, -0.6, pos.z) );
        frontWire.pos( @(pos.x, -0.6, pos.z + 0.75) );

        0.8 => backWire.scaX;
        0.8 => middleWire.scaX;
        0.8 => frontWire.scaX;

        // Set pole pos
        leftPole.setPos( @(pos.x - poleOffset, pos.y, pos.z) );
        rightPole.setPos( @(pos.x + poleOffset, pos.y, pos.z) );

        // Handle crossarms
        @(-poleOffset, -0.6, pos.z) => leftCrossarm.pos;
        @(poleOffset, -0.6, pos.z) => rightCrossarm.pos;
        @(0.1, 0.2, 2.) => leftCrossarm.sca;
        @(0.1, 0.2, 2.) => rightCrossarm.sca;
        Color.BROWN => leftCrossarm.color;
        Color.BROWN => rightCrossarm.color;

        // Connection
        leftPole --> this;
        rightPole --> this;
        leftCrossarm --> this;
        rightCrossarm --> this;
        backWire --> this;
        middleWire --> this;
        frontWire --> this;
        this --> GG.scene();

        // names
        "Left Pole" => leftPole.name;
        "Right Pole" => rightPole.name;
        "Left Crossarm" => leftCrossarm.name;
        "Right Crossarm" => rightCrossarm.name;
        "Wire" => middleWire.name;
        "Telephone Pole" => this.name;
    }

    fun void wireMovement(vec2 waveform[]) {
        while (true) {
            // next graphics frame
            GG.nextFrame() => now;
            backWire.positions( waveform );
            middleWire.positions( waveform );
            frontWire.positions( waveform );
        }
    }
}


class Bird extends GGen {
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

    // Color
    vec3 birdColor;

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

    // song
    int doneSinging;
    int onWire;

    // Shreds
    Shred processAudioShred;
    Shred waveformGraphicsShred;
    Shred animateWingShred;
    Shred animateMouthShred;

    fun @construct(float flapPeriod, float moveSpeed, float shiftY, float shiftZ, vec2 movementPath[]) {
        // set member variables
        1 => inFlight;
        1 => mouthMoving;
        1 => this.doneSinging;
        1 => this.onWire;
        (2 * Math.PI) / (flapPeriod * 1000) => rotateAmount;
        moveSpeed => this.moveSpeed;
        shiftY => this.shiftY;
        shiftZ => this.shiftZ;

        // Handle X movement
        movementPath[0].x => float startingX;
        this.calculateScaleFactor(startingX, shiftZ) * 1.4 => float scalingFactor;
        scaleVectorArray(movementPath, scalingFactor, 1., 0., shiftY);
        movementPath @=> path;

        // Colors
        Color.random() => vec3 birdColor;
        birdColor => this.birdColor;

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

    fun void setDoneSinging() {
        0 => this.doneSinging;
    }

    fun void removeBird() {
        this.body --< this;
        this.head --< this;
    }

    fun float calculateScaleFactor(float startingX, float shiftZ) {
        @(0., 0.) => vec2 screenPos;
        mainCam.screenCoordToWorldPos(screenPos, mainCam.posZ() - shiftZ) @=> vec3 worldPos;
        worldPos.x => float newX;
        return newX / startingX;
    }

    fun drawPath(vec2 currPathGraphics[], int idx, float shiftY) {
        pathGraphics --> GG.scene();

        @(path[idx].x, path[idx].y + shiftY) => vec2 pos;
        currPathGraphics << pos;

        currPathGraphics => pathGraphics.positions;
    }

    fun removePathSegment(vec2 currPathGraphics[]) {
        currPathGraphics.erase(0, 8);
        currPathGraphics => pathGraphics.positions;
    }

    fun removePath(vec2 currPathGraphics[]) {
        currPathGraphics.size() => int size;
        size / 8 => int repeats;
        repeat (repeats) {
            this.removePathSegment(currPathGraphics);
            GG.nextFrame() => now;
        }

        pathGraphics --< GG.scene();
        me.exit();
    }

    fun void moveForward(int idx, float yStepSize) {
        path[idx] => vec2 pos;
        if (idx == 0 || idx >= path.size() - 1) {
            pos.x => this.posX;
            pos.y => this.posY;
            GG.nextFrame() => now;
        } else {
            path[idx + 1] => vec2 nextPos;
            path[idx - 1] => vec2 prevPos;

            (nextPos.x - pos.x) / moveSpeed => float stepX;
            ((nextPos.y - pos.y) + yStepSize) / moveSpeed => float stepY;

            while (this.posX() < nextPos.x) {
                this.posX() + (stepX * GG.dt() * 1000) => this.posX;
                this.posY() + (stepY * GG.dt() * 1000) => this.posY;
                GG.nextFrame() => now;
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
        spork ~ this.removePath(currPathGraphics);
        this.removeBird();

        // Wait for path removal to finish
        currPathGraphics.size() / 8 => int wait;
        repeat (wait) {
            GG.nextFrame() => now;
        }

        // Remove the bird and path graphics from the scene
        pathGraphics --< GG.scene();
        this --< GG.scene();

        // Exit shreds
        this.animateWingShred.exit();
        this.animateMouthShred.exit();
        me.exit();
    }
}


class SingingBird extends Bird {
    fun @construct(float flapPeriod, float moveSpeed, float shiftY, float shiftZ, vec2 movementPath[]) {
        Bird(flapPeriod, moveSpeed, shiftY, shiftZ, movementPath);
        "Singing Bird" => this.name;
    }

    fun void animate(int startLanding, int endLanding, int endTakeoff) {
        // Animations
        spork ~ animateWing() @=> this.animateWingShred;
        spork ~ animateMouth() @=> this.animateMouthShred;
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

        // Bad code :(
        if (currAngle < stopAngle) {
            while (currAngle < stopAngle) {
                currAngle + (stepSize * GG.dt() * 500) => currAngle;
                currAngle => this.rotZ;
                GG.nextFrame() => now;
            }
        } else {
            while (currAngle > stopAngle) {
                currAngle + (stepSize * GG.dt() * 500) => currAngle;
                currAngle => this.rotZ;
                GG.nextFrame() => now;
            }
        }

        stopAngle => this.rotZ;
        me.exit();
    }

    // fun void playSong() {
    //     // Play songs
    //     0.1 => this.song.setGain;
    //     for (Sequence seq : this.song.seqs) {
    //         // Create spectrum visuals
    //         // spork ~ this.createSongSpectrum(seq);

    //         // Handle repeats
    //         0 => int noteIdx;
    //         0 => int repeats;
    //         while (repeats < seq.repeats) {
    //             seq.getNote(noteIdx) @=> Note note;
    //             note.freq => this.song.osc.setFreq;
    //             (noteIdx + 1) % seq.size => noteIdx;
    //             if (noteIdx == 0) repeats++;

    //             note.numBeats * QUARTER_NOTE => now;
    //         }
    //     }

    //     0.0 => this.song.setGain;
    // }

    // fun void createSongSpectrum(Sequence seq) {
    //     // TODO: handle repeats using spectrum
    //     seq.length * QUARTER_NOTE => dur totalDur;
    //     2 => int spectrumsPerSecond;
    //     1::second / spectrumsPerSecond => dur interval;

    //     // handle repeats
    //     now + totalDur => time totalTime;
    //     now => time currTime;
    //     while (currTime < totalTime) {
    //         spork ~ this.animateSongSpectrum();

    //         currTime + interval => currTime;
    //         interval => now;
    //     }

    //     2::second => now;
    // }

    // fun void animateSongSpectrum() {
    //     GLines spectrumGraphics;
    //     vec2 spectrum[];

    //     // Lifespan
    //     1::ms => dur update;
    //     4::second => dur delay;

    //     now + delay => time totalTime;
    //     now => time currTime;

    //     // Spectrum
    //     this.birdColor * 10. => spectrumGraphics.color;
    //     0.2 => spectrumGraphics.width;
    //     @(0.2, 0.1, 1.) => vec3 fullSpectrumScale;
    //     @(0., 0., 1.) => spectrumGraphics.sca;
    //     spectrumGraphics --> this.head;

    //     // Graphics Movement
    //     15. => float xEnd;
    //     delay / update => float numSteps;
    //     xEnd / numSteps => float stepSize;

    //     // Graphics scaling
    //     0 => int shrink;
    //     fullSpectrumScale.x / (numSteps / 2) => float xScaleStepSize;
    //     fullSpectrumScale.y / (numSteps / 2) => float yScaleStepSize;

    //     while (currTime < totalTime) {
    //         // this.song.dsp.getLastNthSpectrum(0) @=> vec2 spectrum[];
    //         this.song.dsp.waveform @=> vec2 spectrum[];
    //         spectrum => spectrumGraphics.positions;

    //         // Move spectrum
    //         spectrumGraphics.posX() + stepSize => spectrumGraphics.posX;

    //         // Scale spectrum down
    //         spectrumGraphics.sca() @=> vec3 currScale;
    //         if ((currScale.x >= fullSpectrumScale.x)) {
    //             1 => shrink;
    //         }
    //         if (shrink == 0) {
    //             currScale.x + xScaleStepSize => spectrumGraphics.scaX;
    //             currScale.y + yScaleStepSize => spectrumGraphics.scaY;
    //         } else if (shrink == 1) {
    //             currScale.x - xScaleStepSize => spectrumGraphics.scaX;
    //             currScale.y - yScaleStepSize => spectrumGraphics.scaY;
    //         }

    //         update + currTime => currTime;
    //         update => now;
    //     }

    //     spectrumGraphics --< this.head;

    //     me.exit();
    // }

    fun void animateDance() {
        while (this.onWire != 0) {
            GG.nextFrame() => now;
        }

        SinOsc danceLFOX(1., Math.random2f(0.1, 1.0)) => blackhole;
        SinOsc danceLFOY(1., Math.random2f(0.1, 1.0)) => blackhole;
        SinOsc danceLFOJump(2.) => blackhole;

        repeat(30) {
            GG.nextFrame() => now;
        }

        this.posY() => float originalY;
        while (this.onWire == 0) {
            // Rotation
            Std.scalef(danceLFOX.last(), -1., 1., -Math.PI / 8, Math.PI / 8) => float xAngle;
            Std.scalef(danceLFOY.last(), -1., 1., -Math.PI / 8, Math.PI / 8) => float yAngle;
            Std.scalef(danceLFOY.last(), -1., 1., 0, Math.PI / 8) => float zAngle;
            xAngle => this.rotX;
            yAngle => this.rotY;
            zAngle => this.rotZ;

            // Position
            Std.scalef(danceLFOJump.last(), -1., 1., 0., 0.5) => float yDelta;
            originalY + yDelta => this.posY;

            GG.nextFrame() => now;
        }

        0. => this.rotX;
        0. => this.rotY;
        0. => this.rotZ;
        originalY => this.posY;
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
        this.rotZ() => float startAngle;
        spork ~ animateRotation(startAngle, stopAngle);

        // Handle landing on the wire
        for (startIdx => int idx; idx < stopIdx; idx++) {
            this.moveForward(idx, yStepSize);
            this.drawPath(currPathGraphics, idx, ((idx - startIdx) * yStepSize));
        }

        // Reset rotation
        this.rotZ() => startAngle;
        spork ~ animateRotation(startAngle, 0.);

        // Snap to wire
        yTarget => this.posY;

        spork ~ removePath(currPathGraphics);

        // Set on wire
        0 => this.onWire;
        spork ~ animateDance();

        // Waiting on the wire
        while (this.doneSinging != 0) {
            GG.nextFrame() => now;
        }

        1 => this.onWire;

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
        this.rotZ() => startAngle;
        spork ~ animateRotation(startAngle, stopAngle);

        // Taking off from the wire
        for (startIdx => int idx; idx < stopIdx; idx++) {
            this.moveForward(idx, yStepSize);
            this.drawPath(currPathGraphics, idx, (stopIdx - idx) * yStepSize * -1);
        }

        // Reset rotation
        this.rotZ() => startAngle;
        spork ~ animateRotation(startAngle, 0.);

        // Flying off the screen
        for (stopIdx => int idx; idx < path.size(); idx++) {
            this.moveForward(idx, 0.);
            this.drawPath(currPathGraphics, idx, 0);
        }

        // Fade out graphics path
        spork ~ removePath(currPathGraphics);
        this.removeBird();

        // Wait for path removal to finish
        currPathGraphics.size() / 8 => int wait;
        repeat (wait) {
            GG.nextFrame() => now;
        }

        // Remove the bird and path graphics from the scene
        pathGraphics --< GG.scene();
        this --< GG.scene();

        // Exit shreds
        this.processAudioShred.exit();
        this.waveformGraphicsShred.exit();
        this.animateWingShred.exit();
        this.animateMouthShred.exit();
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

    fun void addBassBird(AudioProcessing dsp, EnvelopeFollower envFollower, BirdCoordinator bassBirds[]) {
        for (BirdCoordinator bassBird : bassBirds) {
            // Bird generation delay
            bassBird.delay => now;

            // Get Starting Y value
            Math.random2f(1.5, 4.) => float shiftY;

            // Get Z value
            -1 => int zDiff;
            (0.75 * zDiff) + 1. => float shiftZ;

            // Get Pan value
            bassBird.xLandingPos $ float / dsp.WINDOW_SIZE $ float => float landingRatio;
            Std.scalef(landingRatio, 0., 1., -1., 1.) => float panVal;

            // Bass Bird Song
            FMOsc voice(220., 72., 66., 0.6);
            voice.mix => Gain dspGain;

            // Env following
            envFollower.chainFMOsc(voice);

            AudioProcessing birdDSP(dspGain);
            BirdSong song(birdDSP, voice, bassBird.seqs);
            panVal => song.setPan;

            // create new bird
            dsp.getLastNthSpectrum(0) @=> vec2 flightPath[];
            SingingBird bird(.5, 10., shiftY, shiftZ, flightPath);

            // Add bird to bird coordinator
            bassBird.addBird(bird, song);
            spork ~ bassBird.playSong();

            Math.random2f(0.2, 0.6) => float scaleAmt;
            @(0.6, 0.6, 0.6) => bird.sca;

            // let it fly!
            Math.random2(50, 200) => int startLanding;
            bassBird.xLandingPos => int endLanding;
            Math.random2(750, dsp.WINDOW_SIZE - 100) => int endTakeoff;

            bird.animate(startLanding, endLanding, endTakeoff);
        }

        3::minute => now;
    }

    fun void addLeadBird(AudioProcessing dsp, EnvelopeFollower envFollower, BirdCoordinator leadBirds[]) {
        for (BirdCoordinator leadBird : leadBirds) {
            // Bird generation delay
            leadBird.delay => now;

            // Get Starting Y value
            Math.random2f(1.5, 5.) => float shiftY;

            // Get Z value
            Math.random2(0, 1) => int zDiff;
            (0.75 * zDiff) + 1. => float shiftZ;

            // Get Pan value
            leadBird.xLandingPos $ float / dsp.WINDOW_SIZE $ float => float landingRatio;
            Std.scalef(landingRatio, 0., 1., -1., 1.) => float panVal;

            // Bass Bird Song
            DetuneOsc voice(220., 1.0, false);
            voice.mix => Gain dspGain;

            // Env following
            envFollower.chainDetuneOsc(voice);

            AudioProcessing birdDSP(dspGain);
            BirdSong song(birdDSP, voice, leadBird.seqs);
            panVal => song.setPan;

            // create new bird
            dsp.getLastNthSpectrum(0) @=> vec2 flightPath[];
            SingingBird bird(.5, 10., shiftY, shiftZ, flightPath);

            // Add bird to bird coordinator
            leadBird.addBird(bird, song);
            spork ~ leadBird.playSong();

            Math.random2f(0.2, 0.4) => float scaleAmt;
            @(scaleAmt, scaleAmt, scaleAmt) => bird.sca;

            // let it fly!
            Math.random2(50, 200) => int startLanding;
            leadBird.xLandingPos => int endLanding;
            Math.random2(750, dsp.WINDOW_SIZE - 100) => int endTakeoff;

            bird.animate(startLanding, endLanding, endTakeoff);
        }

        3::minute => now;
    }
}


// ************* //
// AUDIO CLASSES //
// ************* //
class CustomOsc {
    // Main mix
    Gain mix;

    fun setFreq(float f) {
        <<< "NOT IMPLEMENTED ERROR: must override setFreq in parent class" >>>;
    }

    fun void exit() {
        // pass
    }

    fun void setGain(float g) {
        g => this.mix.gain;
    }
}


class FMOsc extends CustomOsc {
    // oscillators
    PulseOsc main;
    SinOsc mod;

    // FM variables
    float mainFreq;
    float modAmt;
    float ratio;

    // Shred
    Shred FMShred;

    fun @construct(float mainFreq, float modFreq, float modAmt, float initGain) {
        mainFreq => this.mainFreq;
        modAmt => this.modAmt;

        modFreq / mainFreq => this.ratio;

        mainFreq => main.freq;
        modFreq => mod.freq;

        // handle connections
        main => mix;
        mod => blackhole;

        // main gain
        initGain => mix.gain;

        // start FM
        spork ~ this.modFM() @=> this.FMShred;
    }

    fun void modFM() {
        while (true) {
            (mod.last() * modAmt) + mainFreq => main.freq;
            1::samp => now;
        }
    }

    fun void setFreq(float f) {
        f => this.mainFreq;
        f * this.ratio => mod.freq;
    }

    fun void exit() {
        this.FMShred.exit();
    }
}


class DetuneOsc extends CustomOsc {
    // main oscillators
    PulseOsc main;
    PulseOsc lowDetune;
    SawOsc highDetune;

    // pulse width modulation
    TriOsc pwMod;

    // Remaining UGen chain
    LPF filter;

    fun @construct(float initFreq, float initGain, int enablePWMod) {
        this.setFreq(initFreq);

        // handle connections
        main => mix;
        lowDetune => mix;
        highDetune => mix;

        // set osc gains
        0.33 => lowDetune.gain;
        0.33 => highDetune.gain;
        0.33 => main.gain;

        // filter parameters
        400 => filter.freq;

        // pulse width modulator
        50. => pwMod.freq;
        pwMod => blackhole;
        if (enablePWMod) {
            spork ~ this.pulseWidthModulation();
        }

        // main gain
        initGain => mix.gain;
    }

    fun setFreq(float f) {
        f => main.freq;
        f * 0.996 => lowDetune.freq;
        f * 1.004 => highDetune.freq;
    }

    fun pulseWidthModulation() {
        while (true) {
            Std.scalef(pwMod.last(), -1., 1., 0.45, 0.55) => float mod;
            mod => main.width;
            mod => lowDetune.width;
            1::samp => now;
        }
    }
}


// *********************** //
// NOTE SEQUENCING CLASSES //
// *********************** //
[-3, -1, 0, 2, 4, 5, 7] @=> int NOTE_NAME_MAP[];


class Note {
    // Accidentals
    "#".charAt(0) => int SHARP;
    "b".charAt(0) => int FLAT;
    "R" => string REST;

    // Base Note
    60 => int baseMidi;
    4 => int baseRegister;

    // This Note
    int midi;
    float freq;
    float numBeats;

    fun @construct(string noteSymbol, float numBeats) {
        // Beats
        numBeats => this.numBeats;

        // Handle rests
        if (noteSymbol == REST) {
            -1 => this.midi;
            0. => this.freq;
            return;
        }

        // Handle note
        noteSymbol.length() => int size;

        // Parse symbols from the note string
        noteSymbol.substring(0, 1).upper().charAt(0) - "A".charAt(0) => int noteName;
        -1 => int accidental;
        -1 => int register;

        if (size > 2) {
            noteSymbol.charAt(1) => accidental;
            noteSymbol.charAt(2) - "0".charAt(0) => register;
        } else {
            noteSymbol.charAt(1) - "0".charAt(0) => register;
        }

        // Handle Accidentals
        0 => int diff;
        if (accidental == SHARP) {
            1 => diff;
        } else if (accidental == FLAT) {
            -1 => diff;
        }

        // Handle registers
        NOTE_NAME_MAP[noteName] => int name;
        if (name < 0) {
            register + 1 => register;
        }

        // Calculate Midi and Freq
        this.baseMidi + diff + (name) + (12 * (register - baseRegister)) => this.midi;
        Math.mtof(this.midi) => this.freq;
    }
}


class Sequence {
    Note notes[];
    int repeats;
    int size;
    float length;

    fun @construct(Note notes[], int repeats) {
        notes @=> this.notes;
        repeats => this.repeats;
        notes.size() => this.size;

        // Calculate how long the sequence is in terms of beats
        0. => length;
        for (Note n: notes) {
            n.numBeats + length => length;
        }
        length => this.length;
    }

    fun Note getNote(int idx) {
        return this.notes[idx];
    }
}


class BirdSong {
    AudioProcessing dsp;
    CustomOsc osc;
    Pan2 pan;
    Sequence seqs[];

    fun @construct(AudioProcessing dsp, CustomOsc osc, Sequence seqs[]) {
        dsp @=> this.dsp;
        osc @=> this.osc;
        seqs @=> this.seqs;

        0. => this.setGain;
        0. => pan.pan;
        osc.mix => pan => MASTER;
        osc.mix => PROCESSING_GAIN;
    }

    fun void setPan(float pan) {
        pan => this.pan.pan;
    }

    fun void setFreq(float freq) {
        freq => this.osc.setFreq;
    }

    fun void setGain(float g) {
        g => this.osc.setGain;
    }

    fun void exit() {
        this.osc.exit();
    }
}


class BirdCoordinator {
    int xLandingPos;
    dur delay;
    Sequence seqs[];
    SingingBird bird;
    BirdSong song;

    fun @construct(int xLandingPos, dur delay, Sequence seqs[]) {
        xLandingPos => this.xLandingPos;
        delay => this.delay;
        seqs @=> this.seqs;
    }

    fun void addBird(SingingBird bird, BirdSong song) {
        bird @=> this.bird;
        song @=> this.song;
    }

    fun void playSong() {
        while (bird.onWire != 0) {
            0.5::second => now;
        }

        0.1 => this.song.setGain;
        for (Sequence seq : this.song.seqs) {
            // Handle repeats
            0 => int noteIdx;
            0 => int repeats;
            while (repeats < seq.repeats) {
                seq.getNote(noteIdx) @=> Note note;
                note.freq => this.song.setFreq;
                (noteIdx + 1) % seq.size => noteIdx;
                if (noteIdx == 0) repeats++;

                note.numBeats * QUARTER_NOTE => now;
            }
        }

        0.0 => this.song.setGain;

        1::second => now;
        bird.setDoneSinging();
        this.song.exit();
        me.exit();
    }
}


// ************** //
// NOTE SEQUENCES //
// ************** //
// Bass Sequences
Sequence bassSeqL1(
    [
        new Note("F3", 3.), new Note("A3", 0.5), new Note("G3", 0.5),
        new Note("D3", 2.), new Note("C4", 1.), new Note("A3", 1.)
     ],
    10
);

Sequence bassSeqR1(
    [
        new Note("F2", 3.), new Note("E3", 0.5), new Note("G2", 0.5),
        new Note("D2", 2.), new Note("C3", 1.), new Note("E3", 1.)
    ],
    8
);

Sequence bassSeqL2(
    [
        new Note("D3", 1.5), new Note("C4", 1.), new Note("A3", 1.), new Note("F3", 0.5),
        new Note("D3", 1.5), new Note("C4", 1.), new Note("D4", 1.), new Note("Bb3", 0.5)
     ],
    8
);

Sequence bassSeqR2(
    [
        new Note("A3", 1.5), new Note("F3", 1.), new Note("E3", 1.), new Note("Bb3", 0.5),
        new Note("A3", 1.5), new Note("F3", 1.), new Note("E3", 1.), new Note("C3", 0.5)
     ],
    8
);

// Lead Sequences
Sequence lead1SeqA(
    [
        new Note("F4", 0.5), new Note("G4", 0.5), new Note("A4", 0.5), new Note("Bb4", 1.),
        new Note("A4", 0.5), new Note("G4", 0.5), new Note("A4", 1.), new Note("D4", 0.5),
        new Note("F4", 1.), new Note("F5", 1.), new Note("D5", 1.)
     ],
    6
);


Sequence lead1SeqB(
    [
        new Note("D4", 1.), new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("C4", 0.5),
        new Note("D4", 1.), new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("C4", 0.5),
        new Note("D4", 1.), new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("Eb4", 0.5),
        new Note("D4", 1.), new Note("R", 0.5), new Note("D4", 0.5),  new Note("R", 0.5), new Note("F4", 1.),  new Note("Eb4", 0.5)
     ],
    3
);


Sequence lead2Seq1A(
    [
        new Note("Bb5", 2.25), new Note("R", 0.75), new Note("A5", 0.5), new Note("F5", 0.5),
        new Note("G5", 2.), new Note("D6", 0.667), new Note("C6", 0.666), new Note("G5", 0.667),
        new Note("Bb5", 2.25), new Note("R", 0.75), new Note("A5", 0.5), new Note("F5", 0.5),
        new Note("G5", 1.5), new Note("R", 0.5),
        new Note("F5", 0.334), new Note("Bb5", 0.333), new Note("C6", 0.333),
        new Note("G5", 0.334), new Note("D6", 0.333), new Note("F6", 0.333)
     ],
    2
);


Sequence lead2Seq2A(
    [
        new Note("F5", 1.), new Note("R", 0.5), new Note("Eb5", 0.25), new Note("D4", 0.25),
        new Note("Bb4", 0.5), new Note("D5", 0.5), new Note("Bb4", 1.)
     ],
    3
);


Sequence lead2Seq2B(
    [
        new Note("F5", 1.), new Note("R", 0.5), new Note("Eb5", 0.25), new Note("D4", 0.25),
        new Note("Bb4", 0.5), new Note("G5", 0.5), new Note("F5", 0.75), new Note("R", 0.25)
     ],
    1
);


Sequence lead3Seq1A(
    [
        new Note("Bb6", 0.334), new Note("A6", 0.333), new Note("G6", 0.333),
        new Note("A6", 0.334), new Note("G6", 0.333), new Note("F6", 0.333),
        new Note("G6", 0.334), new Note("F6", 0.333), new Note("Eb6", 0.333),
        new Note("F6", 0.334), new Note("Eb6", 0.333), new Note("D6", 0.333),
        new Note("Eb6", 0.334), new Note("D6", 0.333), new Note("C6", 0.333),
        new Note("D6", 0.334), new Note("C6", 0.333), new Note("Bb5", 0.333),
        new Note("C6", 0.334), new Note("Bb5", 0.333), new Note("A5", 0.333),
        new Note("Bb5", 1.)
     ],
    4
);


Sequence lead3Seq2B(
    [
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("D5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("D5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("D5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("D5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("F5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("F5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("F5", 0.333),
        new Note("Bb4", 0.334), new Note("C5", 0.333), new Note("F5", 0.333),
     ],
    4
);


// Bass
[bassSeqL1, bassSeqL2, bassSeqL1] @=> Sequence bassL1[];
[bassSeqR1, bassSeqR2, bassSeqR1] @=> Sequence bassR1[];


// Leads
[lead1SeqA] @=> Sequence lead1A[];
[lead2Seq1A] @=> Sequence lead1B[];

[lead1SeqB] @=> Sequence lead2A[];
[lead2Seq2A, lead2Seq2B, lead2Seq2A, lead2Seq2B] @=> Sequence lead2B[];

[lead3Seq1A] @=> Sequence lead3A[];
[lead3Seq2B] @=> Sequence lead3B[];


// ***************** //
// BIRD COORDINATION //
// ***************** //
[
    new BirdCoordinator(300, 5::second, bassL1),
    new BirdCoordinator(700, 4::second, bassR1),
] @=> BirdCoordinator bassBirds[];


[
    new BirdCoordinator(400, 20::second, lead1A),
    new BirdCoordinator(500, 7::second, lead1B),

    new BirdCoordinator(250, 22.5::second, lead2A),
    new BirdCoordinator(750, 7::second, lead2B),

    new BirdCoordinator(175, 30::second, lead3A),
    new BirdCoordinator(850, 1.5::second, lead3B),
] @=> BirdCoordinator leadBirds[];


// ******************** //
// OBJECT INSTANTIATION //
// ******************** //
// TODO: Remove when done testing
Gain TEST_INPUT;
adc => TEST_INPUT;

// ADC objects
AudioProcessing mainDSP(PROCESSING_GAIN);
mainDSP.setSlew(0.4);
EnvelopeFollower envFollower();

// Graphics objects
SkyBox sky(30::second);
Grass grass();
TelephonePole wires( @(0., -2., 1), 4);

// Birds!
BirdGenerator birdGen(2::second, 3::second);

// ************** //
// PROGRAM SHREDS //
// ************** //
// Audio processing shreds
spork ~ mainDSP.processInputAudio();
spork ~ mainDSP.processWaveformGraphics();
spork ~ envFollower.follow();

// graphics shreds
spork ~ sky.dayNightCycle();
spork ~ wires.wireMovement(mainDSP.interpWaveform);
spork ~ sky.sun.animateRays(mainDSP.waveform);
spork ~ grass.animateGrass(mainDSP);
spork ~ sky.moon.glow(envFollower);

// Bird movement shreds
spork ~ birdGen.addFlyindBird(mainDSP);
spork ~ birdGen.addBassBird(mainDSP, envFollower, bassBirds);
spork ~ birdGen.addLeadBird(mainDSP, envFollower, leadBirds);


// **** //
// MAIN //
// **** //
while (true) {
    GG.nextFrame() => now;
    // UI
    if (UI.begin("Tutorial")) {
        // show a UI display of the current scenegraph
        UI.scenegraph(GG.scene());
    }
    UI.end();
}

5::minute => now;