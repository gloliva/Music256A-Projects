/*
    Homework 3 Sequencer
    Title: Chordle
    Author: Gregg Oliva
*/

/*
    IDEAS / IMPLEMENTATION
    - change letterboxes to have cube be border and panels be the face
    - Modification words:
        - SHIFT
        - SHFT
        - SFT

        - ROTATE
        - ROTAT
        - ROTS
        - ROT

    - Finishing a game unlocks
        - rotation
        - step algorithms changes?
    - Frequency of letters

    Step Algorithms:
        * Bucket of algorithms for how to step through the sequence
        * When a game is beaten, calculate the edit distance of each line
            - add these up and mod by numAlgorithms to select which algorithm

    When a game is beaten, it
        - "blows up" (i.e. blocks fly from it)
        - maybe turns gold?? or maybe current step turns from red -> gold


*/

// Imports
@import "hw3_files.ck"     // File and Word Handling
@import "hw3_keyboard.ck"  // Keyboard Inputs
@import "hw3_ui.ck"        // UI Handling


// Window Setup
GWindow.title("Chordle");
GWindow.fullscreen();
GWindow.windowSize() => vec2 WINDOW_SIZE;


// Camera
GG.scene().camera() @=> GCamera mainCam;
mainCam.posZ(8.0);


// Background
Color.BLACK => GG.scene().backgroundColor;


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
    GCube border;
    GPlane panels[6];
    GText letterPre;
    GText letterPost;

    // Colors
    vec3 letterColor;
    vec3 permanentColor;

    // Size
    float length;
    float width;
    float depth;

    // Panels
    int activePanelIdx;
    int panelMapping[0];
    GPlane activePanel;

    // Sequencer member variables
    int seqMode;

    fun @construct() {
        // size
        1. => length;
        1. => width;
        1. => depth;

        // Panel Handling
        Color.GRAY => this.permanentColor;
        this.initPanels();
        this.setActivePanel();

        // Init letters
        // Letter prior to rotation
        "." => letterPre.text;
        @(10., 10., 10.) => letterColor;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPre.color;
        0.01 => letterPre.posZ;

        // Letter post rotation
        "." => letterPost.text;
        @(10., 10., 10.) => letterColor;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPost.color;
        0.01 => letterPost.posZ;

        // Init border
        Color.BLACK => border.color;

        // Names
        "Letter Pre Rotation" => this.letterPre.name;
        "Letter Post Rotation" => this.letterPost.name;
        "Border" => this.border.name;
        "LetterBox" => this.name;

        // Connections
        this.letterPre --> this.getPanel("front");
        this.letterPost --> this.getPanel("top");
        this.border --> this;
    }

    fun void initPanels() {
        // Front
        this.panels[0] @=> GPlane panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        0.501 => panel.posZ;
        this.permanentColor => panel.color;
        0 => this.panelMapping["front"];
        "Front panel" => panel.name;
        panel --> this;

        // Back
        this.panels[1] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        -0.501 => panel.posZ;
        this.permanentColor => panel.color;
        1 => this.panelMapping["back"];
        "Back panel" => panel.name;
        panel --> this;

        // Right
        this.panels[2] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        0.501 => panel.posX;
        Math.PI / 2 => panel.rotateY;
        this.permanentColor => panel.color;
        2 => this.panelMapping["right"];
        "Right panel" => panel.name;
        panel --> this;

        // Left
        this.panels[3] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        -0.501 => panel.posX;
        -Math.PI / 2 => panel.rotateY;
        this.permanentColor => panel.color;
        3 => this.panelMapping["left"];
        "Left panel" => panel.name;
        panel --> this;

        // Top
        this.panels[4] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        0.501 => panel.posY;
        -Math.PI / 2 => panel.rotateX;
        this.permanentColor => panel.color;
        4 => this.panelMapping["top"];
        "Top panel" => panel.name;
        panel --> this;

        // Bottom
        this.panels[5] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        -0.501 => panel.posY;
        Math.PI / 2 => panel.rotateX;
        this.permanentColor => panel.color;
        5 => this.panelMapping["bottom"];
        "Bottom panel" => panel.name;
        panel --> this;
    }

    fun GPlane getPanel(string panelPos) {
        this.panelMapping[panelPos] => int panelIdx;
        return this.panels[panelIdx];
    }

    fun int getPanelIdx(string panelPos) {
        return this.panelMapping[panelPos];
    }

    fun void recalculatePanelMapping() {
        this.getPanelIdx("front") => int currFront;
        this.getPanelIdx("back") => int currBack;
        this.getPanelIdx("top") => int currTop;
        this.getPanelIdx("bottom") => int currBottom;

        currTop => this.panelMapping["front"];
        currBack => this.panelMapping["top"];
        currBottom => this.panelMapping["back"];
        currFront => this.panelMapping["bottom"];

        this.getPanelIdx("front") => this.activePanelIdx;
        this.setActivePanel();
    }

    fun void setActivePanel() {
        this.panels[this.activePanelIdx] @=> this.activePanel;
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
            currRotX => this.rotX;
            GG.nextFrame() => now;
        }

        endRotX => this.rotX;
    }

    fun void setTempColor(vec3 color, float intensity) {
        color * intensity => this.activePanel.color;
    }

    fun void setPermanentColor(vec3 color, float intensity) {
        color * intensity => this.permanentColor;
        this.permanentColor => this.activePanel.color;
    }

    fun vec3 getPermanentColor() {
        return this.permanentColor;
    }
}


class ChordleGrid extends GGen {
    LetterBox grid[0][0];
    int numRows;
    int numCols;

    // Size
    float gridLength;
    float gridWidth;

    fun @construct(int numRows, int numCols) {
        numRows => this.numRows;
        numCols => this.numCols;

        1. * this.numRows => this.gridLength;
        1. * this.numCols => this.gridWidth;

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

        // Recalculate mapping
        lb.recalculatePanelMapping();

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

    fun void hideColumn(int col) {
        // TODO: instead of hiding the entire LB,
        // just hide the borders and side panels
        for (int row; row < this.numRows; row++) {
            this.grid[row][col] --< this;
        }
    }

    fun void showColumn(int col) {
        for (int row; row < this.numRows; row++) {
            this.grid[row][col] --> this;
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

    fun void setLayerPos(float x, float y, float z) {
        x => this.posX;
        y => this.posY;
        z => this.posZ;
    }

    fun void rotate(float rotX, float rotY, float rotZ) {
        rotX => this.rotX;
        rotY => this.rotY;
        rotZ => this.rotZ;
    }
}


// Chordle Cube
class ChordleCube extends GGen {
    // Grids
    ChordleGrid sides[6];
    int sidesMapping[0];

    // Size
    int numRows;
    int numCols;
    int numLayers;

    // Active
    ChordleGrid @ activeGrid;

    fun @construct(int numRows, int numCols) {
        numRows => this.numRows;
        numCols => this.numCols;
        numCols => this.numLayers;

        numCols / 2. => float zShift;
        -zShift => this.posZ;
        this.initSides(zShift);
        this.hideColumn("right", numCols - 1);
        this.hideColumn("left", numCols - 1);

        // Set active grid
        this.sides[this.sidesMapping["front"]] @=> this.activeGrid;

        // Names
        "Chordle 3D Cube" => this.name;
    }

    fun void initSides(float shift) {
        // Front
        ChordleGrid front(numRows, numCols);
        front.setLayerPos(0., 0., shift - 0.5);
        front @=> this.sides[0];
        0 => this.sidesMapping["front"];
        front --> this;

        // Back
        ChordleGrid back(numRows, numCols);
        back.setLayerPos(0., 0., shift - 0.5 - (this.numLayers - 1));
        back @=> this.sides[1];
        1 => this.sidesMapping["back"];
        back --> this;

        // Right
        ChordleGrid right(numRows, numCols);
        right.setLayerPos(shift - 0.5 , 0., 0.);
        right.rotate(0., -Math.PI / 2, 0.);
        right @=> this.sides[2];
        2 @=> this.sidesMapping["right"];
        right --> this;

        // Left
        ChordleGrid left(numRows, numCols);
        left.setLayerPos(0.5 - shift , 0., 0.);
        left.rotate(0., Math.PI / 2, 0.);
        left @=> this.sides[3];
        3 => this.sidesMapping["left"];
        left --> this;
    }

    fun void hideColumn(string side, int col) {
        this.sidesMapping[side] => int sideIdx;
        this.sides[sideIdx] @=> ChordleGrid grid;
        grid.hideColumn(col);
    }

    fun void showColumn(string side, int col) {
        this.sidesMapping[side] => int sideIdx;
        this.sides[sideIdx] @=> ChordleGrid grid;
        grid.showColumn(col);
    }

    fun void rotateLeft() {
        Math.PI / 2 => float endRotY;
        this.posY() => float startRotY;
        0. => float currRotY;

        while (currRotY < endRotY) {
            endRotY * GG.dt() => float rotDelta;
            rotDelta + currRotY => currRotY;
            rotDelta => this.rotateY;
            GG.nextFrame() => now;
        }

        startRotY + endRotY => this.rotY;
    }

    fun void rotateRight() {
        Math.PI / 2 => float endRotY;
        this.posY() => float startRotY;
        0. => float currRotY;

        while (currRotY < endRotY) {
            endRotY * GG.dt() => float rotDelta;
            rotDelta + currRotY => currRotY;
            -rotDelta => this.rotateY;
            GG.nextFrame() => now;
        }

        startRotY - endRotY => this.rotY;
    }

    fun void setCubePos(float x, float y) {
        x => this.posX;
        y => this.posY;
    }
}


// Chordle Game
class ChordleGame {
    // Grid size
    int numRows;
    int numCols;
    int numLayers;

    // Grid
    ChordleCube cube;
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
    Event beat;

    // Sequencer position handling
    int startVisuals;
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

    fun @construct(WordSet wordSet, Event beat, int numRows, int numCols) {
        wordSet @=> this.wordSet;
        beat @=> this.beat;
        numRows => this.numRows;
        numCols => this.numCols;

        // Cube
        new ChordleCube(numRows, numCols) @=> this.cube;
        // new ChordleGrid(numRows, numCols) @=> this.grid;
        this.cube.activeGrid @=> this.grid;

        // Game word
        wordSet.getRandom(1) => this.gameWord;
        <<< "Game word: ", this.gameWord >>>;

        // set member variables
        0 => this.currPlayerRow;
        0 => this.currPlayerCol;
        0 => this.active;
        0 => this.complete;
        0 => this.audioOn;

        // Default tempo
        this.setTempo(120., 1.);

        // Init Sequence member variables
        0 => this.startVisuals;
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

    fun void setCubePos(float x, float y) {
        this.cube.setCubePos(x, y);
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
                    if (Type.of(key).name() == kp.SPECIAL_KEY) {
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
                    } else if (Type.of(key).name() == kp.LETTER_KEY && currPlayerCol < numCols) {
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
        while ( !this.startVisuals ) {
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

        this.beat => now;
        1 => this.startVisuals;

        while (true) {
            // Do audio stuff here
            this.grid.getMode(this.currSeqRow, this.currSeqCol) => int mode;

            if (mode == BlockMode.EXACT_MATCH) {
                spork ~ this.playAudio(1.);
            } else if (mode == BlockMode.LETTER_MATCH) {
                Math.random2f(0., 1.) => float chance;
                if (chance > 0.5) spork ~ this.playAudio(0.5);
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

    fun void playAudio(float vol) {
        this.env.value(vol);
        0 => this.buffer.pos;
        1. => this.buffer.rate;
        this.buffer.length() => now;
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
    ChordleGame games[5][10];

    // Word references
    WordSet sets[];

    // Buffer references
    SndBuf buffers[];

    // Transport Event
    Event beat;

    // Screen management
    GameScreen @ screen;

    // Game UI
    GameMatrixUI matrixUI;
    ChordleUI title;

    fun @construct(WordSet sets[], SndBuf buffers[], Event beat, GameScreen screen) {
        sets @=> this.sets;
        buffers @=> this.buffers;
        beat @=> this.beat;
        screen @=> this.screen;

        this.matrixUI.setPos(mainCam, WINDOW_SIZE);
        this.title.setPos(mainCam, WINDOW_SIZE);

        // Default values
        0 => this.numGames;
        0 => this.numRows;
        0 => this.numCols;
        0 => this.activeRow;
        0 => this.activeCol;
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
                if (Type.of(key).name() == kp.SPECIAL_KEY) {
                    if (key.key == this.kp.UP_ARROW) {
                        this.activeRow - 1 => newActiveRow;
                        if (newActiveRow == -1) this.numRows - 1 => newActiveRow;
                    } else if (key.key == this.kp.DOWN_ARROW) {
                        (this.activeRow + 1) % this.numRows => newActiveRow;
                    } else if (key.key == this.kp.LEFT_ARROW) {
                        this.activeCol - 1 => newActiveCol;
                        if (newActiveCol == -1) this.numCols - 1 => newActiveCol;
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

    fun moveScreen(float xDelta, float yDelta) {
        xDelta * GG.dt() => this.screen.translateX;
        yDelta * GG.dt() => this.screen.translateY;
    }

    fun zoomScreen(float zDelta) {
        zDelta * GG.dt() => this.screen.translateZ;
    }

    fun monitorScreenActions() {
        while (true) {
            this.kp.getKeyHeld() @=> Key keys[];
            for (Key key : keys) {
                if (Type.of(key).name() == kp.SPECIAL_KEY) {
                    if (key.key == this.kp.MOVE_UP) {
                        this.moveScreen(0., -5.);
                    } else if (key.key == this.kp.MOVE_DOWN) {
                        this.moveScreen(0., 5.);
                    } else if (key.key == this.kp.MOVE_LEFT) {
                        this.moveScreen(5., 0.);
                    } else if (key.key == this.kp.MOVE_RIGHT) {
                        this.moveScreen(-5., 0.);
                    } else if (key.key == this.kp.PLUS) {
                        this.zoomScreen(5.);
                    } else if (key.key == this.kp.MINUS) {
                        this.zoomScreen(-5.);
                    }
                }
            }

            GG.nextFrame() => now;
        }
    }

    fun manageGames() {
        // Grid size
        -1 => int N;
        -1 => int M;
        -1 => int divider;
        string colSize;

        while (true) {
            this.kp.getKeyPress() @=> Key keys[];
            for (Key key : keys) {
                if (Type.of(key).name() == kp.NUMBER_KEY) {
                    if (N < 0) {
                        key.num => N;
                        this.matrixUI.updateRow(key.key);
                    } else if (M < 0) {
                        key.num => M;
                        key.key => colSize;
                        this.matrixUI.updateCol(key.key);
                    } else if (divider < 0) {
                        key.num => divider;
                        this.matrixUI.updateDivider(key.key);
                    }
                } else if (Type.of(key).name() == kp.SPECIAL_KEY) {
                    // Row and Col and Divider are set
                    if (key.key == this.kp.SPACE && N > 0 && M > 0 && divider > 0) {
                        // Add new game
                        this.sets[colSize] @=> WordSet set;
                        ChordleGame game(set, this.beat, N, M);
                        game.setActive(0);
                        game.setCubePos(5.5 * this.numCols, 0.);  // TODO: update where grid is set
                        game.setTempo(120., divider);
                        game.initAudio(this.buffers);
                        this.screen.addToScreen(game.cube);

                        // Start new game
                        spork ~ game.play();
                        spork ~ game.sequenceAudio();
                        spork ~ game.sequenceVisuals();

                        // Add game to GameManager
                        game @=> this.games[0][this.numCols];
                        this.numCols + 1 => this.numCols;
                        this.numGames++;

                        // Reset
                        -1 => N;
                        -1 => M;
                        -1 => divider;
                        this.matrixUI.reset();
                    }
                }
            }

            GG.nextFrame() => now;
        }
    }
}


class GameScreen extends GGen {
    fun @construct() {
        this --> GG.scene();
        "Game Screen" => this.name;
    }

    fun addToScreen(ChordleGrid grid) {
        grid --> this;
    }

    fun addToScreen(ChordleCube cube) {
        cube --> this;
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


class Transport {
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

    // Global Transport
    Transport transport(120.);
    spork ~ transport.signalBeat();

    // Screen management
    GameScreen screen();

    // Game manager
    GameManager gameManager(sets, buffers, transport.beat, screen);
    spork ~ gameManager.manageGames();
    spork ~ gameManager.selectActiveGame();
    spork ~ gameManager.monitorScreenActions();

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


fun void testCube() {
    ChordleCube cube(5, 5);

    repeat(120) {
        GG.nextFrame() => now;
    }

    cube.rotateRight();

    repeat(120) {
        GG.nextFrame() => now;
    }

    cube.rotateRight();

    repeat(120) {
        GG.nextFrame() => now;
    }

    cube.rotateLeft();

    while (true) {
        // GG.dt() => cube.rotateY;
        GG.nextFrame() => now;
    }
}

// spork ~ testCube();


// Run
main();
