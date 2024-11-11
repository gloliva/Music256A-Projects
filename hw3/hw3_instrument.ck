/*
    Homework 3 Sequencer
    Desc: Instruments
    Author: Gregg Oliva
*/


class FMInstrument {
    FM @ instrument;
    Gain gain;
    Envelope env;

    dur attack;
    dur sustain;
    dur release;

    fun @construct(FM instrument, float initGain) {
        instrument @=> this.instrument;
        initGain => this.gain.gain;

        this.instrument => this.env => this.gain => dac;
    }

    fun void setEnv(dur attack, dur sustain, dur release) {
        attack => this.attack;
        release => this.release;
    }

    fun void setFreq(float freq) {
        freq => this.instrument.freq;
    }

    fun void play() {
        this.instrument.noteOn(1.);
        this.env.ramp(this.attack, 1.);
        this.attack + this.sustain - this.release => now;
        this.env.ramp(this.release, 0.);
        this.release => now;
        this.instrument.noteOff(1.);
    }
}
