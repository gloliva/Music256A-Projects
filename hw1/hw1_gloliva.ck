/*
    Basic program that generates some notes from a scale for
    multiple oscillators.

    Intended as an exploration of fundamental concepts such as
    Ugen chaining, time management, custom class and
    function definitions, and concurrency.
*/

// Setup DAC chain
Gain oscMix => GVerb verb => Envelope fader => Gain masterVolume => dac;
0.5 => oscMix.gain;


// Define constants
52 => int leadStart;
40 => int bassStart;
64 => int fxStart;

[0, 1, 4, 5, 7, 8, 10, 12, 13, 16, 17, 19, 20, 22, 24] @=> int leadScale[]; // Aeolian dominant b2 scale
[0, 4, 5, 7, 10, 12] @=> int bassScale[]; // pentatonic Aeolian dominant scale
leadScale @=> int fxScale[];

100::ms => dur leadAttack;
400::ms => dur leadDecay;
0.1::second => dur bassAttack;
0.5::second => dur bassDecay;
1.4::second => dur bassSustain;
1.5::second => dur fxAttack;
1.5::second => dur fxDecay;
1::second => dur fxSustain;
4::second => dur fxWait;
32::second => dur totalLength;


// Define new oscillator class
class FunkyOsc {
    PulseOsc bass;
    SawOsc lead;
    TriOsc detune;
    SawOsc detune2;
    Gain mix;

    fun @construct(float initFreq, float initGain) {
        freq(initFreq);

        bass => mix;
        lead => mix;
        detune => mix;
        detune2 => mix;

        bass.gain(0.8);
        detune.gain(0.7);
        detune2.gain(0.7);

        mix.gain(initGain);
    }

    fun void freq(float f) {
        f / 2. => bass.freq;
        f => lead.freq;
        f * 0.996 => detune.freq;
        f * 1.004 => detune2.freq;
    }

    fun void bass_pulse(float width) {
        width => bass.width;
    }
}


// Oscillators
FunkyOsc lead(Math.mtof(leadStart), 0.6);
FunkyOsc bass(Math.mtof(bassStart), 0.4);
PulseOsc fx(Math.mtof(fxStart));
PulseOsc fxFifth(Math.mtof(fxStart));

lead.mix => Bitcrusher bc => Envelope leadEnv => oscMix;
bass.mix => LPF bassFilter => Envelope bassEnv => oscMix;
fx => Gain fxGain(0.25) => Envelope fxEnv => oscMix;
fxFifth => fxGain;


// LFOs
TriOsc reverbLFO(0.008) => blackhole;
SinOsc bcLFO(0.05) => blackhole;
TriOsc triLFO(4) => blackhole;
TriOsc filterLFO(0.5) => blackhole;

0.5 => bcLFO.phase;


// Effects parameters
600 => float filterFreq;
filterFreq => bassFilter.freq;

5 => bc.bits;
1 => bc.downsampleFactor;

80 => verb.roomsize;
2::second => verb.revtime;
0.3 => verb.dry;
0.2 => verb.early;
0.5 => verb.tail;


// functions
fun int selectNote(int scale_degrees[], int noteStart) {
    // Select a new random note from the scale
    scale_degrees.size() => int size;
    Math.random2(0, size - 1) => int index;

    return scale_degrees[index] + noteStart;
}

fun void updateLeadNote() {
    while(true) {
        Math.randomf() => float playNote;

        if (playNote > 0.2) {
            lead.freq(
                Std.mtof(selectNote(leadScale, leadStart))
            );
            leadEnv.ramp(leadAttack, 1.);
            leadAttack => now;
            leadEnv.ramp(leadDecay, 0.);
            leadDecay => now;
        } else {
            leadAttack + leadDecay => now;
        }
    }
}

fun void updateBassNote() {
    while(true) {
        bass.freq(
            Std.mtof(selectNote(bassScale, bassStart))
        );
        bassEnv.ramp(bassAttack, 1.);
        bassAttack + bassSustain => now;
        bassEnv.ramp(bassDecay, 0.);
        bassDecay => now;
    }
}

fun void updateFxNote() {
    while(true) {
        fxWait => now;
        selectNote(fxScale, fxStart) => int fxNote;
        fx.freq(Std.mtof(fxNote));
        fxFifth.freq(Std.mtof(fxNote + 7));
        fxEnv.ramp(fxAttack, 1.);
        fxAttack + fxSustain => now;
        fxEnv.ramp(fxDecay, 0.);
        fxDecay => now;
    }
}

fun void updateFxWidth(PulseOsc pulse) {
    // Modulate pulse width
    while(true) {
        pulse.width(Std.scalef(triLFO.last(), -1., 1., 0.2, 0.8));
        0.1::ms => now;
    }
}

fun void updateFilter() {
    // Modulate bass LPF
    while(true) {
        Std.scalef(filterLFO.last(), -1, 1., -200, 600) => float filterDelta;
        filterDelta + filterFreq => bassFilter.freq;
        0.1::ms => now;
    }
}

fun void updateReverb() {
    // Modulate Reverb parameters
    while(true) {
        Std.scalef(reverbLFO.last(), -1., 1., 40, 100) => verb.roomsize;
        Std.scalef(reverbLFO.last(), -1., 1., 0.2, 0.8) => verb.tail;
        0.1::ms => now;
    }
}

fun void updateBitCrush() {
    while(true) {
        Std.ftoi(Std.scalef(bcLFO.last(), -1., 1., 1, 30)) => bc.downsampleFactor;
        Std.ftoi(Std.scalef(bcLFO.last(), -1., 1., 8, 4)) => bc.bits;
        0.1::ms => now;
    }
}


// Pause briefly before starting
0. => masterVolume.gain;
1::second => now;
0.5 => masterVolume.gain;
fader.ramp(2::second, 1.);


// Shred away
spork ~ updateFxWidth(fx);
spork ~ updateFxWidth(fxFifth);
spork ~ updateFilter();
spork ~ updateReverb();
spork ~ updateBitCrush();
spork ~ updateLeadNote() @=> Shred leadShred;
spork ~ updateBassNote() @=> Shred bassShred;
spork ~ updateFxNote() @=> Shred fxShred;


// Play generated piece
totalLength => now;


// Quit shreds
leadShred.exit();
bassShred.exit();
fxShred.exit();


// End piece cohesively
bass.freq(Std.mtof(52));
lead.freq(Std.mtof(56));
fx.freq(Std.mtof(74));
fxFifth.gain(0.);
leadEnv.ramp(leadAttack, 1.);
bassEnv.ramp(bassAttack, 1.);
fxEnv.ramp(0.5::second, 1.);
2::second => now;

leadEnv.ramp(leadDecay, 0.);
bassEnv.ramp(bassDecay, 0.);
fxEnv.ramp(1::second, 0.);
fader.ramp(2::second, 0.);
2::second => now;
