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


// KeyPress
class KeyPoller {
    "BACKSPACE" => string BACKSPACE;
    "ENTER" => string ENTER;

    fun string[] getKeyPress() {
        string keys[0];

        // Letters
        if (GWindow.keyDown(GWindow.Key_A)) keys << "A";
        if (GWindow.keyDown(GWindow.Key_B)) keys << "B";
        if (GWindow.keyDown(GWindow.Key_C)) keys << "C";
        if (GWindow.keyDown(GWindow.Key_D)) keys << "D";
        if (GWindow.keyDown(GWindow.Key_E)) keys << "E";
        if (GWindow.keyDown(GWindow.Key_F)) keys << "F";
        if (GWindow.keyDown(GWindow.Key_G)) keys << "G";
        if (GWindow.keyDown(GWindow.Key_H)) keys << "H";
        if (GWindow.keyDown(GWindow.Key_I)) keys << "I";
        if (GWindow.keyDown(GWindow.Key_J)) keys << "J";
        if (GWindow.keyDown(GWindow.Key_K)) keys << "K";
        if (GWindow.keyDown(GWindow.Key_L)) keys << "L";
        if (GWindow.keyDown(GWindow.Key_M)) keys << "M";
        if (GWindow.keyDown(GWindow.Key_N)) keys << "N";
        if (GWindow.keyDown(GWindow.Key_O)) keys << "O";
        if (GWindow.keyDown(GWindow.Key_P)) keys << "P";
        if (GWindow.keyDown(GWindow.Key_Q)) keys << "Q";
        if (GWindow.keyDown(GWindow.Key_R)) keys << "R";
        if (GWindow.keyDown(GWindow.Key_S)) keys << "S";
        if (GWindow.keyDown(GWindow.Key_T)) keys << "T";
        if (GWindow.keyDown(GWindow.Key_U)) keys << "U";
        if (GWindow.keyDown(GWindow.Key_V)) keys << "V";
        if (GWindow.keyDown(GWindow.Key_W)) keys << "W";
        if (GWindow.keyDown(GWindow.Key_X)) keys << "X";
        if (GWindow.keyDown(GWindow.Key_Y)) keys << "Y";
        if (GWindow.keyDown(GWindow.Key_Z)) keys << "Z";

        // Special characters
        if (GWindow.keyDown(GWindow.Key_Backspace)) keys << this.BACKSPACE;
        if (GWindow.keyDown(GWindow.Key_Enter)) keys << this.ENTER;

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
            fio.readLine() => string word;
            set.add(word);
        }

        return set;
    }
}


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

    fun void setGreen() {
        Color.GREEN => this.box.color;
    }

    fun void setYellow() {
        Color.YELLOW => this.box.color;
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

    // KeyPoller
    KeyPoller kp;

    // This game is the active game
    int active;

    fun @construct(WordSet wordSet, KeyPoller kp, int numRows, int numCols) {
        wordSet @=> this.wordSet;
        numRows => this.numRows;
        numCols => this.numCols;

        // Grid
        new ChordleGrid(numRows, numCols) @=> this.grid;

        // Key Poller
        kp @=> KeyPoller kp;

        // set member variables
        0 => currRow;
        0 => currCol;
        0 => active;
    }

    fun setActive(int mode) {
        mode => this.active;
    }

    fun void play() {
        while (true) {
            if ( this.active ) {
                // Update game based on key presses
                this.kp.getKeyPress() @=> string keys[];
                for (string key : keys) {
                    // Delete letter in current row
                    if (key == kp.BACKSPACE && currCol > 0) {
                        this.grid.removeLetter(currRow, currCol - 1);
                        currCol--;
                    // Add letter to current row
                    } else if (key != kp.BACKSPACE && currCol < numCols) {
                        this.grid.setLetter(key, currRow, currCol);
                        if ( currCol < numCols ) currCol++;
                    }
                }
            }

            GG.nextFrame() => now;
        }
    }
}


// main
fun void main() {
    while (true) {
        GG.nextFrame() => now;
        // UI
        if (UI.begin("Tutorial")) {
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
    grid.grid[0][1].setGreen();

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
        kp.getKeyPress() @=> string keys[];

        for (string key : keys) {
            <<< "Key: ", key >>>;
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




// spork ~ testRotate();
// spork ~ testFile();
// spork ~ testKeyboard();
spork ~ testGame();
main();
