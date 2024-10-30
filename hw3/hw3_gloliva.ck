/*
    Homework 3 Sequencer
    Title: Chordle
    Author: Gregg Oliva
*/

/*
    IDEAS / IMPLEMENTATION
    - Adding new game:
        - new game moves over by 5 in X
        - camera moves +1 in Z and +2.5 in X
*/

// Window Setup
GWindow.title("Chordle");
GWindow.fullscreen();


// Camera
GG.scene().camera() @=> GCamera mainCam;
mainCam.posZ(8.0);


// Background
Color.BLACK => GG.scene().backgroundColor;


// Camera Movement
fun void moveCamera(float xDelta, float yDelta, float zDelta, dur duration) {
    mainCam.pos() => vec3 startPos;

    now + duration => time end;
    while (now < end) {
        GG.nextFrame() => now;
    }

    // Final position adjustment
    @(startPos.x + xDelta, startPos.y + yDelta, startPos.z + zDelta) => mainCam.pos;
}


// Keyboard Handling
class Key {
    string key;
    int num;

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
    fun @construct(string key) {
        Key(key);
        key.toInt() => num;
    }
}



class SpecialKey extends Key {
    fun @construct(string key) {
        Key(key);
    }
}


class KeyPoller {
    // Special Characters
    "BACKSPACE" => string BACKSPACE;
    "ENTER" => string ENTER;

    // Arrow Keys
    "UP_ARROW" => string UP_ARROW;
    "DOWN_ARROW" => string DOWN_ARROW;
    "LEFT_ARROW" => string LEFT_ARROW;
    "RIGHT_ARROW" => string RIGHT_ARROW;

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

        if (GWindow.keyDown(GWindow.Key_Up)) keys << new SpecialKey(this.UP_ARROW);
        if (GWindow.keyDown(GWindow.Key_Down)) keys << new SpecialKey(this.DOWN_ARROW);
        if (GWindow.keyDown(GWindow.Key_Left)) keys << new SpecialKey(this.LEFT_ARROW);
        if (GWindow.keyDown(GWindow.Key_Right)) keys << new SpecialKey(this.RIGHT_ARROW);

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

    fun string[] getWords() {
        string keys[mapSize];
        this.words.getKeys(keys);
        return keys;
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

// ************* //
// GAME HANDLING //
// ************* //
class BlockMode {
    static int NO_MATCH;
    static int EXACT_MATCH;
    static int LETTER_MATCH;
}
0 => BlockMode.NO_MATCH;
1 => BlockMode.EXACT_MATCH;
2 => BlockMode.LETTER_MATCH;


// Chordle Grid
class LetterBox extends GGen {
    // Graphics objects
    GCube box;
    GCube border;
    GText letterPre;
    GText letterPost;

    // Colors
    vec3 letterColor;
    vec3 permanentColor;

    // Sequencer member variables
    int seqMode;

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
        Color.GRAY => this.permanentColor;
        this.permanentColor => box.color;

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

    fun void mode(int mode) {
        mode => this.seqMode;
    }

    fun int mode() {
        return this.seqMode;
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

    fun void setTempColor(vec3 color, float intensity) {
        color * intensity => this.box.color;
    }

    fun void setPermanentColor(vec3 color, float intensity) {
        color * intensity => this.permanentColor;
        this.permanentColor => this.box.color;
    }

    fun vec3 getPermanentColor() {
        return this.permanentColor;
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

        // Set the sequencer mode
        lb.mode(mode);

        // Rotate the block to reveal
        lb.rotate();

        // Set matching color
        if (mode == BlockMode.NO_MATCH) {
            lb.setPermanentColor(Color.DARKGRAY, 0.5);
        } else if (mode == BlockMode.EXACT_MATCH) {
            lb.setPermanentColor(Color.GREEN, 1.);
        } else if (mode == BlockMode.LETTER_MATCH) {
            lb.setPermanentColor(Color.YELLOW, 2.);
        }
    }

    fun void setColor(int row, int col, vec3 color, float intensity, int permanent) {
        if (permanent) {
            this.grid[row][col].setPermanentColor(color, intensity);
        } else {
            this.grid[row][col].setTempColor(color, intensity);
        }
    }

    fun vec3 getColor(int row, int col) {
        return this.grid[row][col].getPermanentColor();
    }

    fun int getMode(int row, int col) {
        return this.grid[row][col].mode();
    }

    fun void setGridPos(float x, float y) {
        x => this.posX;
        y => this.posY;
    }
}


// Chordle Game
class ChordleGame {
    // Grid size
    int numRows;
    int numCols;

    // Grid
    ChordleGrid grid;

    // Current player typing position
    int currPlayerRow;
    int currPlayerCol;

    // Winning words
    WordSet wordSet;
    string gameWord;
    string rowLetters[0];

    // KeyPoller
    KeyPoller kp;

    // Game status
    int active;
    int complete;

    // Timing variables
    float tempo;
    dur quarterNote;
    float clockDivider;

    // Sequencer position handling
    int prevSeqRow;
    int prevSeqCol;
    int currSeqRow;
    int currSeqCol;
    vec3 prevSeqColor;

    // Audio
    int audioOn;
    SndBuf buffer;
    Gain gain;
    Envelope env;

    fun @construct(WordSet wordSet, int numRows, int numCols) {
        wordSet @=> this.wordSet;
        numRows => this.numRows;
        numCols => this.numCols;

        // Grid
        new ChordleGrid(numRows, numCols) @=> this.grid;

        // Game word
        wordSet.getRandom() => this.gameWord;

        // set member variables
        0 => this.currPlayerRow;
        0 => this.currPlayerCol;
        0 => this.active;
        0 => this.complete;
        0 => this.audioOn;

        // Default tempo
        this.setTempo(120., 1.);

        // Init Sequence member variables
        -1 => this.prevSeqRow;
        -1 => this.prevSeqCol;
    }

    fun void setTempo(float tempo, float clockDivider) {
        tempo => this.tempo;
        clockDivider => this.clockDivider;
        (60. / tempo)::second => this.quarterNote;
    }

    fun void setActive(int mode) {
        mode => this.active;
    }

    fun void setGridPos(float x, float y) {
        this.grid.setGridPos(x, y);
    }

    fun initAudio(SndBuf buffers[]) {
        // Check that buffer exists
        if ( !buffers.isInMap(this.gameWord) ) {
            <<< "ERROR: word", this.gameWord, "not found in buffers array.">>>;
            <<< "Make sure you call `loadBuffers` with the correct WordSet.">>>;
            me.exit();
        }

        // Assign this game's buffer
        buffers[this.gameWord] @=> this.buffer;
        this.buffer => this.gain => this.env => dac;
        0.5 => this.gain.gain;
        1 => this.audioOn;
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
            spork ~ this.grid.revealBlock(this.currPlayerRow, colIdx, mode);

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
                        if (key.key == kp.BACKSPACE && currPlayerCol > 0) {
                            // Delete letter in current row
                            this.grid.removeLetter(currPlayerRow, currPlayerCol - 1);
                            this.rowLetters.popBack();
                            currPlayerCol--;
                        } else if (key.key == kp.ENTER && currPlayerCol == numCols) {
                            // Check current row and move to next
                            this.checkRow();
                            this.rowLetters.reset();
                            currPlayerRow++;
                            0 => currPlayerCol;
                        }
                    } else if (Type.of(key).name() == "LetterKey" && currPlayerCol < numCols) {
                        // Add letter to current row
                        this.grid.setLetter(key.key, currPlayerRow, currPlayerCol);
                        this.rowLetters << key.key;
                        currPlayerCol++;
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

    fun void sequenceVisuals() {
        // Wait until player completes first row
        while (this.currPlayerRow < 1) {
            GG.nextFrame() => now;
        }

        while (true) {
            // Set previous block's color
            if (this.prevSeqRow >= 0 && this.prevSeqCol >= 0) {
                this.grid.getColor(this.prevSeqRow, this.prevSeqCol) => vec3 color;
                this.grid.setColor(this.prevSeqRow, this.prevSeqCol, color, 1., 0);
            }

            // Set current block's color
            this.grid.setColor(this.currSeqRow, this.currSeqCol, Color.RED, 1.5, 0);
            GG.nextFrame() => now;
        }
    }

    fun void sequenceAudio() {
        if ( !this.audioOn ) {
            <<< "ERROR: audio is not enabled. Call `initAudio()` before this function." >>>;
            me.exit();
        }

        // Wait until player completes first row
        while (this.currPlayerRow < 1) {
            this.quarterNote / this.clockDivider => now;
        }

        while (true) {
            // Do audio stuff here
            this.grid.getMode(this.currSeqRow, this.currSeqCol) => int mode;

            if (mode == BlockMode.EXACT_MATCH) {
                this.env.value(1.);
                0 => this.buffer.pos;
                1. => this.buffer.rate;
            } else if (mode == BlockMode.LETTER_MATCH) {
                Math.random2f(0., 1.) => float chance;
                if (chance > .5) {
                    this.env.value(0.5);
                    0 => this.buffer.pos;
                    1. => this.buffer.rate;
                }
            }

            // Wait
            this.quarterNote / this.clockDivider => now;
            this.env.value(0.);

            // Set previous values
            this.currSeqCol => this.prevSeqCol;
            this.currSeqRow => this.prevSeqRow;

            // Move to next square
            this.currSeqCol + 1 => this.currSeqCol;
            if (this.currSeqCol >= this.numCols) {
                0 => this.currSeqCol;
                (this.currSeqRow + 1) % this.currPlayerRow => this.currSeqRow;
            }
        }
    }
}


class GameManager {
    // Game state variables
    int numGames;
    int numRows;
    int numCols;
    int activeRow;
    int activeCol;

    // KeyPoller
    KeyPoller kp;

    // Game references
    ChordleGame games[5][5];

    // Word references
    WordSet sets[];

    // Buffer references
    SndBuf buffers[];

    fun @construct(WordSet sets[], SndBuf buffers[]) {
        sets @=> this.sets;
        buffers @=> this.buffers;

        // Default values
        0 => this.numGames;
        0 => this.numRows;
        0 => this.numCols;
        0 => this.activeRow;
        0 => this.activeCol;
    }

    fun addGame(ChordleGame game, int row) {
        this.numGames++;

        if (row > numRows) {

        } else {
            this.games[row] << game;
            this.numCols;
        }
    }

    fun selectActiveGame() {
        // Wait until first game is created
        while (this.numGames < 1) {
            GG.nextFrame() => now;
        }

        // Set first game to be active
        this.games[this.activeRow][this.activeCol].setActive(1);

        while (true) {
            this.activeRow => int newActiveRow;
            this.activeCol => int newActiveCol;

            // Go through keys
            this.kp.getKeyPress() @=> Key keys[];
            for (Key key : keys) {
                if (Type.of(key).name() == "SpecialKey") {
                    if (key.key == this.kp.UP_ARROW) {
                        (this.activeRow - 1) % this.numRows => newActiveRow;
                    } else if (key.key == this.kp.DOWN_ARROW) {
                        (this.activeRow + 1) % this.numRows => newActiveRow;
                    } else if (key.key == this.kp.LEFT_ARROW) {
                        (this.activeCol - 1) % this.numCols => newActiveCol;
                    } else if (key.key == this.kp.RIGHT_ARROW) {
                        (this.activeCol + 1) % this.numCols => newActiveCol;
                    }
                }
            }

            // Set the active game
            if (newActiveRow != this.activeRow || newActiveCol != this.activeCol) {
                // Disable old game
                this.games[this.activeRow][this.activeCol].setActive(0);

                // Activate new game
                newActiveRow => this.activeRow;
                newActiveCol => this.activeCol;
                this.games[this.activeRow][this.activeCol].setActive(1);
            }

            // Poll wait
            GG.nextFrame() => now;
        }
    }

    fun manageGames() {
        // Grid size
        -1 => int N;
        -1 => int M;
        string colSize;

        while (true) {
            this.kp.getKeyPress() @=> Key keys[];
            for (Key key : keys) {
                if (Type.of(key).name() == "NumberKey") {
                    if (N < 0) {
                        key.num => N;
                    } else if (M < 0) {
                        key.num => M;
                        key.key => colSize;
                    }
                }
            }

            if (N > 0 && M > 0) {
                // Add new game
                <<< "New game with size: ", N, M >>>;
                this.sets[colSize] @=> WordSet set;
                ChordleGame game(set, N, M);
                game.setActive(0);
                game.setGridPos(5. * this.numCols, 0.);
                game.setTempo(120., 1.);
                game.initAudio(this.buffers);

                // Start new game
                spork ~ game.play();
                spork ~ game.sequenceAudio();
                spork ~ game.sequenceVisuals();

                // Add game to GameManager
                game @=> this.games[0][this.numCols];
                this.numCols + 1 => this.numCols;
                this.numGames++;

                // Update camera
                if (this.numGames > 1) {
                    Math.pow(2., this.numCols - 1) => float zDelta;
                    spork ~ moveCamera(2.5, 0., zDelta, 1::second);
                }

                // Reset
                -1 => N;
                -1 => M;
            }

            GG.nextFrame() => now;
        }
    }
}


// UI
class GameMatrixUI extends GGen {
    GPlane box;
    GText row;
    GText cross;
    GText col;

    fun @construct() {
        // Scale
        2. => box.scaX;
        0.5 => row.scaX;
        0.5 => cross.scaX;
        0.5 => col.scaX;

        // Text
        "1" => row.text;
        "x" => cross.text;
        "1" => col.text;

        // Text color
        @(0., 0., 0., 1.) => row.color;
        @(0., 0., 0., 1.) => cross.color;
        @(0., 0., 0., 1.) => col.color;

        // Positions
        @(-0.3, 0., 0.1) => row.pos;
        0.1 => cross.posZ;
        @(0.3, 0., 0.1) => col.pos;

        1. => this.posZ;

        // Connections
        row --> box;
        cross --> box;
        col --> box;
        box --> this --> GG.scene();
    }
}


// ************** //
// AUDIO HANDLING //
// ************** //
fun void loadBuffers(SndBuf buffers[], WordSet set) {
    set.getWords() @=> string words[];
    for (string word : words) {
        "samples/" + word + ".wav" => string sampleFile;
        new SndBuf(sampleFile) @=> buffers[word];
    }
}


// ************ //
// MAIN PROGRAM //
// ************ //
fun void main() {
    // Read in all words
    FileReader fr;
    fr.parseFile("words/4letters.txt") @=> WordSet letterSet4;
    fr.parseFile("words/5letters.txt") @=> WordSet letterSet5;

    // Map of word sets
    WordSet sets[0];
    letterSet4 @=> sets["4"];
    letterSet5 @=> sets["5"];

    // Load buffers
    SndBuf buffers[0];
    loadBuffers(buffers, letterSet4);
    loadBuffers(buffers, letterSet5);

    // Instantiate UI
    // GameMatrixUI ui();  // TODO: Enable eventually

    // Game manager
    GameManager gameManager(sets, buffers);
    spork ~ gameManager.manageGames();
    spork ~ gameManager.selectActiveGame();

    // Instantiate first game
    // ChordleGame initGame(letterSet5, 6, 5);
    // initGame.setActive(1);
    // initGame.setTempo(120., 2.);
    // initGame.initAudio(buffers);

    // spork ~ initGame.play();
    // spork ~ initGame.sequenceAudio();
    // spork ~ initGame.sequenceVisuals();

    // ChordleGame game(letterSet4, 4, 4);
    // game.setActive(0);
    // game.setGridPos(5., 0.);
    // game.setTempo(120., 1.);
    // game.initAudio(buffers);


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


// TESTING
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

// Run
main();
