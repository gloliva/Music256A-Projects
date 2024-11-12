/*
    Homework 3 Sequencer
    Desc: File Handling
    Author: Gregg Oliva
*/


public class WordSet {
    int words[0];
    string wordsList[0];
    int mapSize;

    fun void add(string word) {
        this.mapSize++;
        1 => this.words[word];
        this.wordsList << word;
    }

    fun int find(string word) {
        return this.words.isInMap(word);
    }

    fun int size() {
        return this.mapSize;
    }

    fun string[] getWords() {
        string keys[this.mapSize];
        this.words.getKeys(keys);
        return keys;
    }

    fun string getRandom() {
        return this.getRandom(0);
    }

    fun string getRandom(int remove) {
        string keys[this.mapSize];
        this.words.getKeys(keys);

        // Get word
        Math.random2(0, this.mapSize - 1) => int idx;
        keys[idx] => string word;

        if (remove) {
            this.words.erase(word);
            this.mapSize--;
        }

        return word;
    }

    fun string getNext() {
        // Pops from the front
        if (mapSize > 0) {
            this.wordsList[0] => string word;
            this.wordsList.popFront();
            this.words.erase(word);
            this.mapSize--;
            return word;
        }
        return "";
    }
}


public class FileReader {
    FileIO fio;

    fun WordSet parseFile(string filename) {
        WordSet set();

        // Open file for reading
        fio.open(filename, FileIO.READ);
        if (!fio.good()) {
            <<< "Failed to open file: ", filename >>>;
            me.exit();
        } else {
            <<< "Successfully opened ", filename >>>;
        }

        // Read each line as a word
        while (fio.more()) {
            fio.readLine().upper() => string word;

            // Skip commented out lines
            if (word.charAt(0) != "#".charAt(0)) {
                set.add(word);
            }
        }

        return set;
    }
}
