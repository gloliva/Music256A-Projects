/*
    Homework 3 Sequencer
    Desc: Events
    Author: Gregg Oliva
*/

// Signals on the beat
public class Transport {
    // Timing variables
    float tempo;
    dur quarterNote;
    Event beat;

    fun @construct(float tempo) {
        tempo => this.tempo;
        (60. / tempo)::second => this.quarterNote;
    }

    fun void signalBeat() {
        while (true) {
            this.beat.signal();
            this.quarterNote * 4 => now;
        }
    }
}

// Signal when a word is submitted
public class WordEvent extends Event {
    string _word;

    fun string word() {
        return this._word;
    }

    fun void word(string w) {
        w => this._word;
    }
}
