/*
    Homework 3 Sequencer
    Desc: Notes and Scales
    Author: Gregg Oliva
*/


public class ScaleDegree {
    int degree;
    int octaveDiff;

    fun @construct(int degree, int octaveDiff) {
        degree => this.degree;
        octaveDiff => this.octaveDiff;
    }
}


public class Scale {
    int size;
    int degrees[];
    int base;

    fun @construct(int degrees[], int base) {
        degrees @=> this.degrees;
        degrees.size() => this.size;
        base => this.base;
    }

    fun float getFreqFromDegree(int degree) {
        return this.getFreqFromDegree(degree, 0);
    }

    fun float getFreqFromDegree(int degree, int octaveDiff) {
        (degree / size)$int => int octaves;
        degree % size => degree;

        base + (12 * octaves) + (12 * octaveDiff) + degrees[degree] => float midiNote;
        return Math.mtof(midiNote);
    }
}


public class StandardScales {
    Scale major;
    Scale majorPentatonic;

    int base;

    fun @construct() {
        48 => this.base;

        new Scale([0, 2, 4, 5, 7, 9, 11], this.base) @=> this.major;
        new Scale([0, 2, 5, 7, 9], this.base) @=> this.majorPentatonic;
    }
}
