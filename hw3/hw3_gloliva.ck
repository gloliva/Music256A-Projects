/*
    Homework 3 Sequencer
    Title: Chordle
    Author: Gregg Oliva
*/

// Window Setup
GWindow.title("Chordle");
GWindow.fullscreen();


// Camera
GG.scene().camera() @=> GCamera mainCam;
mainCam.posZ(8.0);


// Background
Color.BLACK => GG.scene().backgroundColor;


// Keyboard Handling
class Key {
    string key;

    fun @construct(string key) {
        key => this.key;
    }
}


class LetterKey extends Key {
    fun @construct(string key) {
        Key(key);
    }
}


class NumberKey extends Key {
    int num;

    fun @construct(string key) {
        Key(key);
        Std.atoi(key) => num;
    }
}



class SpecialKey extends Key {
    fun @construct(string key) {
        Key(key);
    }
}


class KeyPoller {
    "BACKSPACE" => string BACKSPACE;
    "ENTER" => string ENTER;

    fun Key[] getKeyPress() {
        Key keys[0];

        // Letters
        if (GWindow.keyDown(GWindow.Key_A)) keys << new LetterKey("A");
        if (GWindow.keyDown(GWindow.Key_B)) keys << new LetterKey("B");
        if (GWindow.keyDown(GWindow.Key_C)) keys << new LetterKey("C");
        if (GWindow.keyDown(GWindow.Key_D)) keys << new LetterKey("D");
        if (GWindow.keyDown(GWindow.Key_E)) keys << new LetterKey("E");
        if (GWindow.keyDown(GWindow.Key_F)) keys << new LetterKey("F");
        if (GWindow.keyDown(GWindow.Key_G)) keys << new LetterKey("G");
        if (GWindow.keyDown(GWindow.Key_H)) keys << new LetterKey("H");
        if (GWindow.keyDown(GWindow.Key_I)) keys << new LetterKey("I");
        if (GWindow.keyDown(GWindow.Key_J)) keys << new LetterKey("J");
        if (GWindow.keyDown(GWindow.Key_K)) keys << new LetterKey("K");
        if (GWindow.keyDown(GWindow.Key_L)) keys << new LetterKey("L");
        if (GWindow.keyDown(GWindow.Key_M)) keys << new LetterKey("M");
        if (GWindow.keyDown(GWindow.Key_N)) keys << new LetterKey("N");
        if (GWindow.keyDown(GWindow.Key_O)) keys << new LetterKey("O");
        if (GWindow.keyDown(GWindow.Key_P)) keys << new LetterKey("P");
        if (GWindow.keyDown(GWindow.Key_Q)) keys << new LetterKey("Q");
        if (GWindow.keyDown(GWindow.Key_R)) keys << new LetterKey("R");
        if (GWindow.keyDown(GWindow.Key_S)) keys << new LetterKey("S");
        if (GWindow.keyDown(GWindow.Key_T)) keys << new LetterKey("T");
        if (GWindow.keyDown(GWindow.Key_U)) keys << new LetterKey("U");
        if (GWindow.keyDown(GWindow.Key_V)) keys << new LetterKey("V");
        if (GWindow.keyDown(GWindow.Key_W)) keys << new LetterKey("W");
        if (GWindow.keyDown(GWindow.Key_X)) keys << new LetterKey("X");
        if (GWindow.keyDown(GWindow.Key_Y)) keys << new LetterKey("Y");
        if (GWindow.keyDown(GWindow.Key_Z)) keys << new LetterKey("Z");

        // Numbers
        if (GWindow.keyDown(GWindow.Key_0)) keys << new NumberKey("0");
        if (GWindow.keyDown(GWindow.Key_1)) keys << new NumberKey("1");
        if (GWindow.keyDown(GWindow.Key_2)) keys << new NumberKey("2");
        if (GWindow.keyDown(GWindow.Key_3)) keys << new NumberKey("3");
        if (GWindow.keyDown(GWindow.Key_4)) keys << new NumberKey("4");
        if (GWindow.keyDown(GWindow.Key_5)) keys << new NumberKey("5");
        if (GWindow.keyDown(GWindow.Key_6)) keys << new NumberKey("6");
        if (GWindow.keyDown(GWindow.Key_7)) keys << new NumberKey("7");
        if (GWindow.keyDown(GWindow.Key_8)) keys << new NumberKey("8");
        if (GWindow.keyDown(GWindow.Key_9)) keys << new NumberKey("9");

        // Special characters
        if (GWindow.keyDown(GWindow.Key_Backspace)) keys << new SpecialKey(this.BACKSPACE);
        if (GWindow.keyDown(GWindow.Key_Enter)) keys << new SpecialKey(this.ENTER);

        return keys;
    }
}


// File Handling
class WordSet {
    int words[0];
    int mapSize;

    fun void add(string word) {
        this.mapSize++;
        1 => this.words[word];
    }

    fun int find(string word) {
        return this.words.isInMap(word);
    }

    fun int size() {
        return this.mapSize;
    }

    fun string getRandom() {
        string keys[this.mapSize];
        this.words.getKeys(keys);

        Math.random2(0, this.mapSize - 1) => int idx;
        return keys[idx];
    }
}


class FileReader {
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
            set.add(word);
        }

        return set;
    }
}


// Letter Matching Modes
class BlockMode {
    static int NO_MATCH;
    static int EXACT_MATCH;
    static int LETTER_MATCH;
}
1 => BlockMode.EXACT_MATCH;
2 => BlockMode.LETTER_MATCH;


// Chordle Grid
class LetterBox extends GGen {
    GCube box;
    GCube border;
    GText letterPre;
    GText letterPost;

    vec3 letterColor;

    fun @construct() {
        // Init letters
        // Letter prior to rotation
        "." => letterPre.text;
        @(10., 10., 10.) => letterColor;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPre.color;
        0.51 => letterPre.posZ;

        // Letter post rotation
        "." => letterPost.text;
        @(10., 10., 10.) => letterColor;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPost.color;
        0.51 => letterPost.posY;
        -1 * (Math.PI / 2) => letterPost.rotX;

        // Init box
        @(0.95, 0.95, 0.95) => box.sca;
        Color.GRAY => box.color;

        // Init border
        0.90 => border.scaZ;
        Color.BLACK => border.color;

        // Names
        "Letter Pre Rotation" => this.letterPre.name;
        "Letter Post Rotation" => this.letterPost.name;
        "Box" => this.box.name;
        "Border" => this.border.name;
        "LetterBox" => this.name;

        // Connections
        this.letterPre --> this.box;
        this.letterPost --> this.box;
        this.box --> this;
        this.border --> this;
    }

    fun void setLetter(string text) {
        text => this.letterPre.text;
        text => this.letterPost.text;
        @(letterColor.x, letterColor.y, letterColor.z, 1.) => letterPre.color;
        @(letterColor.x, letterColor.y, letterColor.z, 1.) => letterPost.color;
    }

    fun void removeLetter() {
        "." => letterPre.text;
        "." => letterPost.text;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPre.color;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPost.color;
    }

    fun void setPos(float x, float y) {
        x => this.posX;
        y => this.posY;
    }

    fun void rotate() {
        Math.PI / 2 => float endRotX;
        0. => float currRotX;

        while (currRotX < endRotX) {
            (endRotX * GG.dt()) + currRotX => currRotX;
            currRotX => this.box.rotX;
            GG.nextFrame() => now;
        }

        endRotX => this.box.rotX;
    }

    fun void setColor(vec3 color, float intensity) {
        color * intensity => this.box.color;
    }
}


class ChordleGrid extends GGen {
    LetterBox grid[0][0];
    int numRows;
    int numCols;

    fun @construct(int numRows, int numCols) {
        numRows => this.numRows;
        numCols => this.numCols;

        // Instantiate grid
        for (int row; row < numRows; row++) {
            LetterBox gridRow[numCols];
            this.grid << gridRow;
        }

        // Organize grid
        (numCols - 1) / 2. => float xOffset;
        (numRows - 1) / 2. => float yOffset;

        for (int row; row < numRows; row++) {
            for (int col; col < numCols; col++) {
                // Set position in the grid
                col - xOffset => float x;
                yOffset - row => float y;
                this.grid[row][col].setPos(x, y);

                // Connect to this object
                this.grid[row][col] --> this;
            }
        }

        // Connect to scene
        this --> GG.scene();

        // Names
        "ChordleGrid" => this.name;
    }

    fun void setLetter(string text, int row, int col) {
        if (row >= this.numRows || row < 0) {
            <<< "Invalid row in ChordleGrid.setLetter:", row, "Num Rows:", this.numRows >>>;
            return;
        }

        if (col >= this.numCols || col < 0) {
            <<< "Invalid col in ChordleGrid.setLetter:", col, "Num Cols:", this.numCols >>>;
            return;
        }

        this.grid[row][col] @=> LetterBox lb;
        lb.setLetter(text);
    }

    fun void removeLetter(int row, int col) {
        if (row >= this.numRows || row < 0) {
            <<< "Invalid row in ChordleGrid.removeLetter:", row, "Num Rows:", this.numRows >>>;
            return;
        }

        if (col >= this.numCols || col < 0) {
            <<< "Invalid col in ChordleGrid.removeLetter:", col, "Num Cols:", this.numCols >>>;
            return;
        }

        this.grid[row][col] @=> LetterBox lb;
        lb.removeLetter();
    }

    fun void revealBlock(int row, int col, int mode) {
        this.grid[row][col] @=> LetterBox lb;
        lb.rotate();

        if (mode == BlockMode.EXACT_MATCH) {
            lb.setColor(Color.GREEN, 1.);
        } else if (mode == BlockMode.LETTER_MATCH) {
            lb.setColor(Color.YELLOW, 2.);
        }
    }
}


// Chordle Game
class ChordleGame {
    int currRow;
    int currCol;

    int numRows;
    int numCols;

    // Grid
    ChordleGrid grid;

    // Winning words
    WordSet wordSet;
    string gameWord;
    string rowLetters[0];

    // KeyPoller
    KeyPoller kp;

    // Game status
    int active;
    int complete;

    fun @construct(WordSet wordSet, KeyPoller kp, int numRows, int numCols) {
        wordSet @=> this.wordSet;
        numRows => this.numRows;
        numCols => this.numCols;

        // Grid
        new ChordleGrid(numRows, numCols) @=> this.grid;

        // Game word
        wordSet.getRandom() => this.gameWord;

        // Key Poller
        kp @=> KeyPoller kp;

        // set member variables
        0 => currRow;
        0 => currCol;
        0 => active;
        0 => complete;
    }

    fun void setActive(int mode) {
        mode => this.active;
    }

    fun void getGameLetterFreq(int gameLetterFreq[]) {
        for (int charIdx; charIdx < this.gameWord.length(); charIdx++) {
            this.gameWord.substring(charIdx, 1) => string letter;

            if (gameLetterFreq.isInMap(letter)) {
                1 + gameLetterFreq[letter] => gameLetterFreq[letter];
            } else {
                1 => gameLetterFreq[letter];
            }
        }
    }

    fun int checkGameComplete(int matches[]) {
        for (int match : matches) {
            if (match != 1) return false;
        }
        return true;
    }

    fun void checkRow() {
        int gameLetterFreq[0];
        this.getGameLetterFreq(gameLetterFreq);

        // Loop through initially to determine exact letter matching
        int matches[this.rowLetters.size()];
        for (int colIdx; colIdx < this.rowLetters.size(); colIdx++) {
            this.rowLetters[colIdx] => string letter;
            this.gameWord.find(letter, colIdx) => int gameWordIdx;
            if (colIdx == gameWordIdx) {
                BlockMode.EXACT_MATCH => matches[colIdx];
                gameLetterFreq[letter] - 1 => gameLetterFreq[letter];
            }
        }

        // Loop through againt to determine correct letters in the wrong spot
        for (int colIdx; colIdx < this.rowLetters.size(); colIdx++) {
            this.rowLetters[colIdx] => string letter;
            this.gameWord.find(letter) => int gameWordIdx;
            if (colIdx != gameWordIdx && gameWordIdx != -1 && gameLetterFreq[letter] > 0) {
                BlockMode.LETTER_MATCH => matches[colIdx];
                gameLetterFreq[letter] - 1 => gameLetterFreq[letter];
            }
        }

        // Loop through again to rotate each block
        for (int colIdx; colIdx < this.rowLetters.size(); colIdx++) {
            // Get mode
            matches[colIdx] => int mode;

            // Rotate current column block
            spork ~ this.grid.revealBlock(this.currRow, colIdx, mode);

            // Wait between each rotation
            now + 0.5::second => time end;
            while (now < end) {
                GG.nextFrame() => now;
            }
        }

        this.checkGameComplete(matches) => this.complete;
    }

    fun void play() {
        // Loop while word hasn't been found
        while ( !this.complete ) {

            // If this game is the active game
            if ( this.active ) {
                // Update game based on key presses
                this.kp.getKeyPress() @=> Key keys[];
                for (Key key : keys) {
                    if (Type.of(key).name() == "SpecialKey") {
                        if (key.key == kp.BACKSPACE && currCol > 0) {
                            // Delete letter in current row
                            this.grid.removeLetter(currRow, currCol - 1);
                            this.rowLetters.popBack();
                            currCol--;
                        } else if (key.key == kp.ENTER && currCol == numCols) {
                            // Check current row and move to next
                            this.checkRow();
                            this.rowLetters.reset();
                            currRow++;
                            0 => currCol;
                        }
                    } else if (Type.of(key).name() == "LetterKey" && currCol < numCols) {
                        // Add letter to current row
                        this.grid.setLetter(key.key, currRow, currCol);
                        this.rowLetters << key.key;
                        currCol++;
                    }
                }
            }

            // Next frame
            GG.nextFrame() => now;
        }

        // This game is done
        while (true) {
            GG.nextFrame() => now;
        }
    }
}


// main
fun void main() {
    // Read in all words
    FileReader fr;
    fr.parseFile("5letters.txt") @=> WordSet letterSet5;

    // Keyboard polling
    KeyPoller kp();

    // Instantiate first game
    ChordleGame initGame(letterSet5, kp, 6, 5);
    initGame.setActive(1);
    spork ~ initGame.play();

    while (true) {
        GG.nextFrame() => now;
        // UI
        if (UI.begin("HW3")) {
            // show a UI display of the current scenegraph
            UI.scenegraph(GG.scene());
        }
        UI.end();
    }
}

// TEST
fun void testRotate() {
    ChordleGrid grid(6, 5);
    grid.setLetter("X", 0, 0);
    grid.setLetter("C", 0, 1);

    repeat(120) {
        GG.nextFrame() => now;
    }

    grid.grid[0][1].rotate();
}

fun void testFile() {
    FileReader file;

    file.parseFile("5letters.txt") @=> WordSet set;

    <<< "Words size: ", set.size() >>>;

    repeat (4) {
        set.getRandom() => string word;
        <<< "Random Word", word >>>;
    }
}

fun void testKeyboard() {
    KeyPoller kp();

    while (true) {
        kp.getKeyPress() @=> Key keys[];

        for (Key key : keys) {
            <<< "Key: ", key.key >>>;
        }
        GG.nextFrame() => now;
    }
}

fun void testGame() {
    FileReader file;
    file.parseFile("5letters.txt") @=> WordSet set;
    KeyPoller kp();

    ChordleGame game(set, kp, 6, 5);
    game.setActive(1);
    game.play();
}

main();
