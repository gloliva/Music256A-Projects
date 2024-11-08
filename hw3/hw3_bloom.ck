/*
    Homework 3 Sequencer
    Desc: Bloom
    Author: Gregg Oliva
*/

public class Bloom {
    OutputPass outPass;
    BloomPass bloomPass;

    fun @construct(float thresh, float intensity) {
        this.setUp();
        this.threshold(thresh);
        this.intensity(intensity);
    }

    fun void setUp() {
        GG.outputPass() @=> this.outPass;
        GG.renderPass() --> this.bloomPass --> this.outPass;

        this.bloomPass.input(GG.renderPass().colorOutput());
        this.outPass.input(this.bloomPass.colorOutput());
    }

    fun void threshold(float val) {
        this.bloomPass.threshold(val);
    }

    fun void intensity(float val) {
        this.bloomPass.intensity(val);
    }

    fun void radius(float val) {
        this.bloomPass.radius(val);
    }

    fun void levels(int val) {
        this.bloomPass.levels(val);
    }
}
