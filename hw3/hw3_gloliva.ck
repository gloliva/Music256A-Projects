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

    IDEA 1
    Different Sides are Divisions of the Beat
    - Side one would be quarter
    - Side two is eighth note
    - Side three 16th etc

    IDEA 2
    Different sides are different samples
    - they all play at the same time

    IDEA 3
    After beating the game, it rotates around each after each completion

    IDEA 4:
    - TODO: This is a good one!!!
    - When you beat the game, a melody is created ontop of the cube
    - Maybe it is based on the letters that you chose to get to the word

    IDEA 5
    - The more games you beat, the more "coloreful circles" (with bloom) fly around
      in the background. i.e. it gets more colorful

    IDEA 6
    - Flash the words you've used on screen in the background on beat

    IDEA 7:
    - PAN melodies based on their position

    Step Algorithms:
        * Bucket of algorithms for how to step through the sequence
        * When a game is beaten, calculate the edit distance of each line
            - add these up and mod by numAlgorithms to select which algorithm

    When a game is beaten, it
        - "blows up" (i.e. blocks fly from it)
        - maybe turns gold?? or maybe current step turns from red -> gold
*/

// Imports
@import "hw3_background.ck" // Background Events
@import "hw3_bloom.ck"      // Bloom
@import "hw3_events.ck"     // Events
@import "hw3_files.ck"      // File and Word Processing
@import "hw3_instrument.ck" // Instrument and Audio
@import "hw3_keyboard.ck"   // Keyboard Input
@import "hw3_scales.ck"     // Scales
@import "hw3_ui.ck"         // UI


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

    // Scaling
    // int inflate;

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
        @(6., 6., 6.) => letterColor;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPre.color;
        0.01 => letterPre.posZ;

        // Letter post rotation
        "." => letterPost.text;
        @(6., 6., 6.) => letterColor;
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
    }

    fun void removeLetter() {
        "." => letterPre.text;
        "." => letterPost.text;
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPre.color;
    }

    fun void hideBorder() {
        this.border --< this;
    }

    fun void showBorder() {
        this.border --> this;
    }

    fun void hidePanel(string panelPos) {
        this.getPanel(panelPos) --< this;
    }

    fun void showPanel(string panelPos) {
        this.getPanel(panelPos) --> this;
    }

    fun void hideNonActivePanels() {
        for (int idx; idx < this.panels.size(); idx++) {
            if (idx != this.activePanelIdx) {
                this.panels[idx] --< this;
            }
        }
    }

    fun void showNonActivePanels() {
        for (int idx; idx < this.panels.size(); idx++) {
            if (idx != this.activePanelIdx) {
                this.panels[idx] --> this;
            }
        }
    }

    fun void setPos(float x, float y) {
        x => this.posX;
        y => this.posY;
    }

    fun void rotate() {
        Math.PI / 2 => float endRotX;
        0. => float currRotX;

        // Enable post text
        @(letterColor.x, letterColor.y, letterColor.z, 1.) => letterPost.color;

        while (currRotX < endRotX) {
            (endRotX * GG.dt()) + currRotX => currRotX;
            currRotX => this.rotX;
            GG.nextFrame() => now;
        }

        endRotX => this.rotX;

        // Disable initial text
        @(letterColor.x, letterColor.y, letterColor.z, 0.) => letterPre.color;
    }

    fun void resetScale() {
        @(1., 1., 1.) => this.sca;
    }

    fun void inflate() {
        1.1 => float endSca;
        while (this.scaX() < endSca) {
            this.scaX() * GG.dt() => float dtX;
            this.scaY() * GG.dt() => float dtY;
            this.scaZ() * GG.dt() => float dtZ;
            @(this.scaX() + dtX, this.scaY() + dtY, this.scaZ() + dtZ) => this.sca;
            GG.nextFrame() => now;
        }
    }

    fun void deflate() {
        1.0 => float endSca;
        while (this.scaX() > endSca) {
            this.scaX() * GG.dt() => float dtX;
            this.scaY() * GG.dt() => float dtY;
            this.scaZ() * GG.dt() => float dtZ;
            @(this.scaX() - dtX, this.scaY() - dtY, this.scaZ() - dtZ) => this.sca;
            GG.nextFrame() => now;
        }
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

    // Beat Division
    float beatDiv;

    fun @construct(int numRows, int numCols) {
        numRows => this.numRows;
        numCols => this.numCols;

        1. * this.numRows => this.gridLength;
        1. * this.numCols => this.gridWidth;

        // Beat div
        1. => this.beatDiv;

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

    fun void setBeatDiv(float beatDiv) {
        beatDiv => this.beatDiv;
    }

    fun float getBeatDiv() {
        return this.beatDiv;
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

    fun void setCompleteRow(int row) {
        for (int col; col < this.numCols; col++) {
            this.grid[row][col] @=> LetterBox lb;
            lb.setPermanentColor(@(1.5, 0.84, 0.), 10.);
        }
    }

    fun hideEdges() {
        for (int row; row < this.numRows; row++) {
            this.grid[row][0] @=> LetterBox lbStart;
            this.grid[row][this.numCols - 1] @=> LetterBox lbEnd;

            lbStart.hidePanel("left");
            lbEnd.hidePanel("right");
        }
    }

    fun void hideNonActiveBlocks() {
        for (int row; row < this.numRows; row++) {
            this.grid[row][0] @=> LetterBox lbStart;
            this.grid[row][this.numCols - 1] @=> LetterBox lbEnd;

            // Hide border
            lbStart.hideBorder();
            lbEnd.hideBorder();

            // Hide all panels that don't show letters
            lbStart.hideNonActivePanels();
            lbEnd.hideNonActivePanels();
        }
    }

    fun showEdges() {
        for (int row; row < this.numRows; row++) {
            this.grid[row][0] @=> LetterBox lbStart;
            this.grid[row][this.numCols - 1] @=> LetterBox lbEnd;

            lbStart.showPanel("left");
            lbEnd.showPanel("right");
        }
    }

    fun void showNonActiveBlocks() {
        for (int row; row < this.numRows; row++) {
            this.grid[row][0] @=> LetterBox lbStart;
            this.grid[row][this.numCols - 1] @=> LetterBox lbEnd;

            // Show border
            lbStart.showBorder();
            lbEnd.showBorder();

            // Show all panels
            lbStart.showNonActivePanels();
            lbEnd.showNonActivePanels();
        }
    }

    fun void resetScale() {
        for (int row; row < this.numRows; row++) {
            for (int col; col < this.numCols; col++) {
                this.grid[row][col].resetScale();
            }
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
        rotY => this.rotateY;
        rotX => this.rotX;
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

    // Rotation
    float yCurrRotation;

    // Active
    int activeGridIdx;
    ChordleGrid @ activeGrid;

    fun @construct(int numRows, int numCols) {
        numRows => this.numRows;
        numCols => this.numCols;
        numCols => this.numLayers;

        // Rotation
        0. => this.yCurrRotation;

        numCols / 2. => float shift;
        -shift => this.posZ;
        this.initSides(shift);
        this.hideNonActiveBlocks("left");
        this.hideNonActiveBlocks("right");

        // Set active grid
        this.sides[this.sidesMapping["front"]] @=> this.activeGrid;

        // Names
        "Chordle 3D Cube" => this.name;
    }

    fun void initSides(float shift) {
        // Front
        ChordleGrid front(numRows, numCols);
        front.setLayerPos(0., 0., shift - 0.5);
        front.setBeatDiv(1.); // Quarter notes
        front @=> this.sides[0];
        0 => this.sidesMapping["front"];
        front --> this;

        // Back
        ChordleGrid back(numRows, numCols);
        back.setLayerPos(0., 0., shift - 0.5 - (this.numLayers - 1));
        back.setBeatDiv(4.); // Sixteenth notes
        back.rotate(Math.PI, Math.PI, Math.PI);
        back @=> this.sides[1];
        1 => this.sidesMapping["back"];
        back --> this;

        // Right
        ChordleGrid right(numRows, numCols);
        right.setLayerPos(shift - 0.5 , 0., 0.);
        right.setBeatDiv(2.); // Eighth notes
        right.rotate(0., Math.PI / 2, 0.);
        right @=> this.sides[2];
        2 @=> this.sidesMapping["right"];
        right --> this;

        // Left
        ChordleGrid left(numRows, numCols);
        left.setLayerPos(0.5 - shift , 0., 0.);
        left.setBeatDiv(0.5); // Half notes
        left.rotate(0., -Math.PI / 2, 0.);
        left @=> this.sides[3];
        3 => this.sidesMapping["left"];
        left --> this;
    }

    fun void hideEdges(string side) {
        this.sidesMapping[side] => int sideIdx;
        this.sides[sideIdx] @=> ChordleGrid grid;
        grid.hideEdges();
    }

    fun void hideNonActiveBlocks(string side) {
        this.sidesMapping[side] => int sideIdx;
        this.sides[sideIdx] @=> ChordleGrid grid;
        grid.hideNonActiveBlocks();
    }

    fun void showEdges(string side) {
        this.sidesMapping[side] => int sideIdx;
        this.sides[sideIdx] @=> ChordleGrid grid;
        grid.showEdges();
    }

    fun void showNonActiveBlocks(string side) {
        this.sidesMapping[side] => int sideIdx;
        this.sides[sideIdx] @=> ChordleGrid grid;
        grid.showNonActiveBlocks();
    }

    fun updateVisualsOnRotation() {
        // Hide all panels except the front (the letter panel)
        // on the left and right grids
        this.showEdges("front");
        this.showEdges("back");
        this.hideNonActiveBlocks("front");
        this.hideNonActiveBlocks("back");

        // Show all panels (except edges) on the front and back grids
        this.showNonActiveBlocks("left");
        this.showNonActiveBlocks("right");
        this.hideEdges("left");
        this.hideEdges("right");
    }

    fun void lookAtRight() {
        if (this.yCurrRotation == 0.) {
            this.lookAt(@(this.posX(), this.posY(), -100.));
        } else if ( this.yCurrRotation == Math.PI / 2) {
            this.lookAt(@(-100., this.posY(), this.posZ()));
        } else if (this.yCurrRotation == Math.PI) {
            this.lookAt(@(this.posX(), this.posY(), 100.));
        } else {
            this.lookAt(@(100., this.posY(), this.posZ()));
        }
    }

    fun void lookAtLeft() {
        if (this.yCurrRotation == 0.) {
            this.lookAt(@(this.posX(), this.posY(), 100.));
        } else if ( this.yCurrRotation == Math.PI / 2) {
            this.lookAt(@(100., this.posY(), this.posZ()));
        } else if (this.yCurrRotation == Math.PI) {
            this.lookAt(@(this.posX(), this.posY(), -100.));
        } else {
            this.lookAt(@(-100., this.posY(), this.posZ()));
        }
    }

    fun void rotateRight() {
        Math.PI / 2 => float endRotY;
        this.posY() => float startRotY;
        0. => float currRotY;

        while (currRotY < endRotY) {
            endRotY * GG.dt() => float rotDelta;
            rotDelta + currRotY => currRotY;
            rotDelta => this.rotateY;
            GG.nextFrame() => now;
        }

        // Adjust Y rotation to be exact position
        this.yCurrRotation + endRotY => this.yCurrRotation;
        this.yCurrRotation % (2 * Math.PI) => this.yCurrRotation;
        // this.lookAtRight();

        // Update Panels and Borders
        this.updateVisualsOnRotation();

        // Update side mapping
        this.sidesMapping["front"] => int currFront;
        this.sidesMapping["back"] => int currBack;
        this.sidesMapping["right"] => int currRight;
        this.sidesMapping["left"] => int currLeft;

        currFront => this.sidesMapping["right"];
        currBack => this.sidesMapping["left"];
        currRight => this.sidesMapping["back"];
        currLeft => this.sidesMapping["front"];

        this.setActiveGrid();
    }

    fun void rotateLeft() {
        Math.PI / 2 => float endRotY;
        this.posY() => float startRotY;
        0. => float currRotY;

        // Rotate cube
        while (currRotY < endRotY) {
            endRotY * GG.dt() => float rotDelta;
            rotDelta + currRotY => currRotY;
            -rotDelta => this.rotateY;
            GG.nextFrame() => now;
        }

        // Adjust Y rotation to be exact position
        this.yCurrRotation - endRotY => this.yCurrRotation;
        this.yCurrRotation % (Math.PI) => this.yCurrRotation;
        // this.lookAtLeft();

        // Update Panels and Borders
        this.updateVisualsOnRotation();


        // Update side mapping
        this.sidesMapping["front"] => int currFront;
        this.sidesMapping["back"] => int currBack;
        this.sidesMapping["right"] => int currRight;
        this.sidesMapping["left"] => int currLeft;

        currFront => this.sidesMapping["left"];
        currBack => this.sidesMapping["right"];
        currRight => this.sidesMapping["front"];
        currLeft => this.sidesMapping["back"];

        this.setActiveGrid();
    }

    fun void setActiveGrid() {
        this.sidesMapping["front"] => this.activeGridIdx;
        this.sides[this.activeGridIdx] @=> this.activeGrid;
    }

    fun void setCubePos(float x, float y) {
        x => this.posX;
        y => this.posY;
    }

    fun ChordleGrid getGridByIdx(int idx) {
        return this.sides[idx];
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
    int activeGridIdx;

    // Current player typing position
    int currPlayerRow[4];
    int currPlayerCol[4];

    // Position in Games grid
    int colLocation;
    int rowLocation;

    // Winning words
    WordSet wordSet;
    string gameWord;
    string rowLetters[4][0];
    WordEvent @ wordEvent;

    // KeyPoller
    KeyPoller kp;

    // Game status
    int active;
    int complete[4];
    int numGamesComplete;

    // Timing variables
    float tempo;
    dur quarterNote;
    Event beat;

    // Melody
    Event melody;
    FMInstrument @ instrument;
    Scale @ scale;

    // Sequencer position handling
    int startVisuals[4];
    int prevSeqRow[4];
    int prevSeqCol[4];
    int currSeqRow[4];
    int currSeqCol[4];

    // Audio
    int audioOn;
    SndBuf buffer;
    Gain gain;
    Envelope env;

    fun @construct(WordSet wordSet, Event beat, WordEvent wordEvent, FMInstrument instrument, Scale scale, int numRows, int numCols) {
        wordSet @=> this.wordSet;
        beat @=> this.beat;
        wordEvent @=> this.wordEvent;
        instrument @=> this.instrument;
        scale @=> this.scale;
        numRows => this.numRows;
        numCols => this.numCols;

        // Init Cube
        new ChordleCube(numRows, numCols) @=> this.cube;
        this.cube.activeGridIdx => this.activeGridIdx;
        this.cube.activeGrid @=> this.grid;

        // Game word
        wordSet.getRandom(1) => this.gameWord;
        <<< "Game word: ", this.gameWord >>>;

        // Default tempo
        this.setTempo(120.);

        // Init Sequence member variables
        initList(this.prevSeqRow, -1);
        initList(this.prevSeqCol, -1);
    }

    fun void setTempo(float tempo) {
        tempo => this.tempo;
        (60. / tempo)::second => this.quarterNote;
    }

    fun void setActive(int mode) {
        mode => this.active;
    }

    fun void setCubePos(float x, float y) {
        this.cube.setCubePos(x, y);
    }

    fun void setCubeGamePos(int colLocation, int rowLocation) {
        colLocation => this.colLocation;
        rowLocation => this.rowLocation;
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
        int matches[this.rowLetters[this.activeGridIdx].size()];
        for (int colIdx; colIdx < this.rowLetters[this.activeGridIdx].size(); colIdx++) {
            this.rowLetters[this.activeGridIdx][colIdx] => string letter;
            this.gameWord.find(letter, colIdx) => int gameWordIdx;
            if (colIdx == gameWordIdx) {
                BlockMode.EXACT_MATCH => matches[colIdx];
                gameLetterFreq[letter] - 1 => gameLetterFreq[letter];
            }
        }

        // Loop through againt to determine correct letters in the wrong spot
        for (int colIdx; colIdx < this.rowLetters[this.activeGridIdx].size(); colIdx++) {
            this.rowLetters[this.activeGridIdx][colIdx] => string letter;
            this.gameWord.find(letter) => int gameWordIdx;
            if (colIdx != gameWordIdx && gameWordIdx != -1 && gameLetterFreq[letter] > 0) {
                BlockMode.LETTER_MATCH => matches[colIdx];
                gameLetterFreq[letter] - 1 => gameLetterFreq[letter];
            }
        }

        // Loop through again to rotate each block
        for (int colIdx; colIdx < this.rowLetters[this.activeGridIdx].size(); colIdx++) {
            // Get mode
            matches[colIdx] => int mode;

            // Rotate current column block
            spork ~ this.grid.revealBlock(this.currPlayerRow[this.activeGridIdx], colIdx, mode);

            // Wait between each rotation
            now + 0.5::second => time end;
            while (now < end) {
                GG.nextFrame() => now;
            }
        }

        this.checkGameComplete(matches) => this.complete[this.activeGridIdx];
        if ( this.complete[this.activeGridIdx] ) {
            this.numGamesComplete++;
        }
    }

    fun void signalWord() {
        "" => string word;
        for (string char : this.rowLetters[this.activeGridIdx]) {
            word + char => word;
        }

        word => this.wordEvent.word;
        this.wordEvent.signal();
    }

    fun void play() {
        while (true) {
            // If this game is the active game
            if ( this.active ) {
                this.kp.getKeyPress() @=> Key keys[];
                // If this side isn't complete
                if ( !this.complete[this.activeGridIdx] ) {
                    // Update game based on key presses
                    for (Key key : keys) {
                        if (Type.of(key).name() == kp.SPECIAL_KEY) {
                            if (key.key == kp.BACKSPACE && currPlayerCol[this.activeGridIdx] > 0) {
                                // Delete letter in current row
                                this.grid.removeLetter(currPlayerRow[this.activeGridIdx], currPlayerCol[this.activeGridIdx] - 1);
                                this.rowLetters[this.activeGridIdx].popBack();
                                currPlayerCol[this.activeGridIdx]--;
                            } else if (key.key == kp.ENTER && currPlayerCol[this.activeGridIdx] == numCols) {
                                // Check current row and move to next
                                this.checkRow();
                                this.signalWord();
                                this.rowLetters[this.activeGridIdx].reset();
                                currPlayerRow[this.activeGridIdx]++;
                                0 => currPlayerCol[this.activeGridIdx];
                            } else if (key.key == kp.LEFT_BRACKET) {
                                this.cube.rotateLeft();
                            } else if (key.key == kp.RIGHT_BRACKET) {
                                this.cube.rotateRight();
                            }
                        } else if (Type.of(key).name() == kp.LETTER_KEY && currPlayerCol[this.activeGridIdx] < numCols) {
                            // Add letter to current row
                            this.grid.setLetter(key.key, currPlayerRow[this.activeGridIdx], currPlayerCol[this.activeGridIdx]);
                            this.rowLetters[this.activeGridIdx] << key.key;
                            currPlayerCol[this.activeGridIdx]++;
                        }
                    }
                // Side is complete, still allow for rotations
                } else {
                    for (Key key : keys) {
                        if (Type.of(key).name() == kp.SPECIAL_KEY) {
                            // Still allow rotations for a completed game
                            if (key.key == kp.LEFT_BRACKET) {
                                this.cube.rotateLeft();
                            } else if (key.key == kp.RIGHT_BRACKET) {
                                this.cube.rotateRight();
                            }
                        }
                    }
                }
            }

            // Get Active Side
            this.cube.activeGridIdx => this.activeGridIdx;
            this.cube.activeGrid @=> this.grid;
            GG.nextFrame() => now;
        }
    }

    fun void sequenceVisuals(int sideIdx) {
        // Wait until player completes first row
        while ( !this.startVisuals[sideIdx] ) {
            GG.nextFrame() => now;
        }

        // Get grid
        this.cube.getGridByIdx(sideIdx) @=> ChordleGrid grid;

        while (true) {
            // Set previous block's color
            if (this.prevSeqRow[sideIdx] >= 0 && this.prevSeqCol[sideIdx] >= 0) {
                grid.getColor(this.prevSeqRow[sideIdx], this.prevSeqCol[sideIdx]) => vec3 color;
                grid.setColor(this.prevSeqRow[sideIdx], this.prevSeqCol[sideIdx], color, 1., 0);
                if (sideIdx == this.activeGridIdx) {
                    spork ~ grid.grid[this.prevSeqRow[sideIdx]][this.prevSeqCol[sideIdx]].deflate();
                } else {
                    grid.grid[this.prevSeqRow[sideIdx]][this.prevSeqCol[sideIdx]].resetScale();
                }
            }

            // Set current block's color
            grid.setColor(this.currSeqRow[sideIdx], this.currSeqCol[sideIdx], Color.RED, 1.5, 0);
            if (sideIdx == this.activeGridIdx) {
                spork ~ grid.grid[this.currSeqRow[sideIdx]][this.currSeqCol[sideIdx]].inflate();
            } else {
                grid.grid[this.currSeqRow[sideIdx]][this.currSeqCol[sideIdx]].resetScale();
            }
            GG.nextFrame() => now;
        }
    }

    fun void sequenceAudio(int sideIdx) {
        if ( !this.audioOn ) {
            <<< "ERROR: audio is not enabled. Call `initAudio()` before this function." >>>;
            me.exit();
        }

        // Get grid
        this.cube.getGridByIdx(sideIdx) @=> ChordleGrid grid;

        // Wait until player completes first row
        while (this.currPlayerRow[sideIdx] < 1) {
            this.quarterNote / grid.beatDiv => now;
        }

        this.beat => now;
        1 => this.startVisuals[sideIdx];

        while (true) {
            // Do audio stuff here
            grid.getMode(this.currSeqRow[sideIdx], this.currSeqCol[sideIdx]) => int mode;

            if (mode == BlockMode.EXACT_MATCH && sideIdx == this.activeGridIdx) {
                spork ~ this.playAudio(1.);
            } else if (mode == BlockMode.LETTER_MATCH && sideIdx == this.activeGridIdx) {
                Math.random2f(0., 1.) => float chance;
                if (chance > 0.5) spork ~ this.playAudio(0.5);
            }

            // Signal melody to step
            this.melody.signal();

            // Wait
            this.quarterNote / grid.beatDiv => now;
            this.env.value(0.);

            // Set previous values
            this.currSeqCol[sideIdx] => this.prevSeqCol[sideIdx];
            this.currSeqRow[sideIdx] => this.prevSeqRow[sideIdx];

            // Move to next square
            this.currSeqCol[sideIdx] + 1 => this.currSeqCol[sideIdx];
            if (this.currSeqCol[sideIdx] >= this.numCols) {
                0 => this.currSeqCol[sideIdx];
                (this.currSeqRow[sideIdx] + 1) % this.currPlayerRow[sideIdx] => this.currSeqRow[sideIdx];
            }
        }
    }

    fun void generateMelody(ScaleDegree degrees[], ChordleGrid grid, int sideIdx) {
        for (int row; row < this.currPlayerRow[sideIdx]; row++) {
            for (int col; col < grid.numCols; col++) {
                grid.grid[row][col] @=> LetterBox lb;
                lb.letterPost.text() => string letter;

                (letter.charAt(0) - "A".charAt(0)) - ("M".charAt(0) - "A".charAt(0)) => int degree;
                1 => float chance;
                if (lb.mode() == BlockMode.LETTER_MATCH) 0.5 => chance;
                if (lb.mode() == BlockMode.NO_MATCH) 0.1 => chance;
                if (Math.random2f(0., 1.) > chance) -1 => degree;

                degrees << new ScaleDegree(degree, 0);
            }
        }
    }

    fun void playMelody(int sideIdx) {
        // Get grid
        this.cube.getGridByIdx(sideIdx) @=> ChordleGrid grid;

        while ( !this.complete[sideIdx] ) {
            this.quarterNote / grid.beatDiv => now;
        }

        // Set up instrument
        this.quarterNote / grid.beatDiv => dur beatLength;
        50::ms => dur attack;
        50::ms => dur release;
        beatLength - attack - release => dur sustain;
        this.instrument.setEnv(attack, sustain, release);

        [-0.8, -0.33, 0.33, 0.8] @=> float panVal[];
        this.instrument.setPan(panVal[this.colLocation]);

        ScaleDegree scaleDegrees[0];
        this.generateMelody(scaleDegrees, grid, sideIdx);

        ((this.currSeqRow[sideIdx] * this.numCols) + this.currSeqCol[sideIdx]) + 1 => int currIdx;
        scaleDegrees.size() => int melodyLength;
        currIdx % melodyLength => currIdx;

        while (true) {
            // Wait for beat step
            this.melody => now;
            scaleDegrees[currIdx] @=> ScaleDegree degree;

            if (sideIdx == this.activeGridIdx && degree.degree != -1) {
                // Get frequency from scale degree
                this.scale.getFreqFromDegree(degree.degree, degree.octaveDiff) => float freq;

                // Play instrument
                this.instrument.setFreq(freq);
                spork ~ this.instrument.play();
            }

            (currIdx + 1) % melodyLength => currIdx;
        }
    }

    fun void moveWhileActive() {
        0.5 => float moveAmount;
        0.05 => float scaleAmount;
        1 => int direction;

        this.cube.posY() => float origY;
        this.cube.posY() - 0.15 => float startY;
        this.cube.posY() + 0.15 => float endY;

        while (true) {
            if ( this.active ) {
                direction * moveAmount * GG.dt() => this.cube.translateY;
                (direction * GG.dt() * scaleAmount) => float dtSca;
                @(this.cube.scaX() + dtSca, this.cube.scaY() + dtSca, this.cube.scaZ() + dtSca) => this.cube.sca;

                if (this.cube.posY() > endY && direction == 1) {
                    -1 => direction;
                } else if (this.cube.posY() < startY && direction == -1) {
                    1 => direction;
                }
            } else {
                origY => this.cube.posY;
                @(1., 1., 1.) => this.cube.sca;
            }

            GG.nextFrame() => now;
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
    int numCols[5];
    int maxCols;
    int activeRow;
    int activeCol;
    int numGamesComplete;

    // New game location
    int rowPointer;
    int colPointer;

    // KeyPoller
    KeyPoller kp;

    // Game references
    ChordleGame games[5][4];

    // Word references
    WordSet sets[];

    // Buffer references
    SndBuf buffers[];

    // Transport Event
    Event @ beat;

    // Word Event
    WordEvent @ wordEvent;

    // Melody
    StandardScales @ scaleManager;

    // Screen management
    GameScreen @ screen;

    // Game UI
    GameMatrixUI matrixUI;
    ChordleUI title;

    fun @construct(WordSet sets[], SndBuf buffers[], Event beat, WordEvent wordEvent, StandardScales scaleManager, GameScreen screen) {
        sets @=> this.sets;
        buffers @=> this.buffers;
        beat @=> this.beat;
        wordEvent @=> this.wordEvent;
        scaleManager @=> this.scaleManager;
        screen @=> this.screen;

        this.matrixUI.setPos(mainCam, WINDOW_SIZE);
        this.title.setPos(mainCam, WINDOW_SIZE);

        // Default values
        0 => this.numGames;
        1 => this.numRows;
        4 => this.maxCols;
        0 => this.activeRow;
        0 => this.activeCol;

        0 => this.rowPointer;
        0 => this.colPointer;
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
                        if (this.activeCol >= this.numCols[newActiveRow]) this.numCols[newActiveRow] - 1 => newActiveCol;
                    } else if (key.key == this.kp.DOWN_ARROW) {
                        (this.activeRow + 1) % this.numRows => newActiveRow;
                        if (this.activeCol >= this.numCols[newActiveRow]) this.numCols[newActiveRow] - 1 => newActiveCol;
                    } else if (key.key == this.kp.LEFT_ARROW) {
                        this.activeCol - 1 => newActiveCol;
                        if (newActiveCol == -1) this.numCols[this.activeRow] - 1 => newActiveCol;
                    } else if (key.key == this.kp.RIGHT_ARROW) {
                        (this.activeCol + 1) % this.numCols[this.activeRow] => newActiveCol;
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

    fun void monitorCompleteGames() {
        while (true) {
            0 => int completedGames;
            for (ChordleGame rows[] : this.games) {
                for (ChordleGame game : rows) {
                    game.numGamesComplete + completedGames => completedGames;
                }
            }

            completedGames => this.numGamesComplete;
            GG.nextFrame() => now;
        }
    }

    fun FM newInstrument() {
        Math.random2(0, 3) => int choice;
        // if (choice == 0) {
        //     return new HnkyTonk();
        // } else if (choice == 1) {
        //     return new BeeThree();
        // } else if (choice == 2) {
        //     return new FrencHrn();
        // } else {
        //     return new Wurley();
        // }

        return new HnkyTonk();
    }

    fun void manageGames() {
        // Grid size
        -1 => int N;
        -1 => int M;
        string colSize;

        while (true) {
            this.kp.getKeyPress() @=> Key keys[];
            this.kp.getKeyHeld() @=> Key heldKeys[];
            for (Key key : keys) {
                if (Type.of(key).name() == kp.NUMBER_KEY) {
                    if (N < 0) {
                        key.num => N;
                        this.matrixUI.updateRow(key.key);
                    } else if (M < 0) {
                        key.num => M;
                        key.key => colSize;
                        this.matrixUI.updateCol(key.key);
                    }
                } else if (Type.of(key).name() == kp.SPECIAL_KEY) {
                    // Row and Col are set
                    if (key.key == this.kp.SPACE && N > 0 && M > 0) {
                        // Add new game
                        this.sets[colSize] @=> WordSet set;
                        FMInstrument instrument(this.newInstrument(), 0.2);
                        ChordleGame game(set, this.beat, this.wordEvent, instrument, this.scaleManager.majorPentatonic, N, M);
                        game.setActive(0);
                        game.setCubePos(5.5 * this.colPointer, -5.5 * this.rowPointer);  // TODO: update where grid is set
                        game.setCubeGamePos(this.colPointer, this.rowPointer);
                        game.setTempo(120.);
                        game.initAudio(this.buffers);
                        this.screen.addToScreen(game.cube);

                        // Start new game
                        spork ~ game.play();
                        spork ~ game.moveWhileActive();
                        for(int idx; idx < 4; idx++) {
                            spork ~ game.sequenceAudio(idx);
                            spork ~ game.sequenceVisuals(idx);
                            spork ~ game.playMelody(idx);
                        }

                        // Add game to GameManager
                        game @=> this.games[this.rowPointer][this.colPointer];
                        this.numCols[this.rowPointer] + 1 => this.numCols[this.rowPointer];

                        if (this.colPointer < this.maxCols - 1) {
                            this.colPointer++;
                        } else {
                            this.rowPointer++;
                            this.numRows++;
                            0 => this.colPointer;
                            this.games.size() + 1 => this.games.size;
                        }

                        this.numGames++;

                        // Reset
                        -1 => N;
                        -1 => M;
                        this.matrixUI.reset();
                    }
                }
            }

            for (Key key : heldKeys) {
                if (Type.of(key).name() == kp.SPECIAL_KEY) {
                    if (key.key == this.kp.SHIFT_BACKSPACE) {
                        if (M > -1) {
                            -1 => M;
                            this.matrixUI.updateCol(".");
                        }
                        else if (N > -1) {
                            -1 => N;
                            this.matrixUI.updateRow(".");
                        }
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


// **************** //
// HELPER FUNCTIONS //
// **************** //
fun void loadBuffers(SndBuf buffers[], WordSet set) {
    set.getWords() @=> string words[];
    for (string word : words) {
        "samples/" + word + ".wav" => string sampleFile;
        new SndBuf(sampleFile) @=> buffers[word];
    }
}


fun void initList(int arr[], int init) {
    for (int idx; idx < arr.size(); idx++) {
        init => arr[idx];
    }
}


// ************ //
// MAIN PROGRAM //
// ************ //
fun void main() {
    // Bloom handling
    Bloom bloom(5, 0.75);
    bloom.radius(1.0);
    bloom.levels(4);

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

    // Scales
    StandardScales scaleManager;

    // Global Transport
    Transport transport(120.);
    spork ~ transport.signalBeat();

    // Word Event
    WordEvent wordEvent;

    // Screen management
    GameScreen screen();

    // Background
    BackgroundManager background(wordEvent);
    spork ~ background.addLetters();
    spork ~ background.spawnBackgroundLetters();
    spork ~ background.spawnBackgroundWords();

    // Game manager
    GameManager gameManager(sets, buffers, transport.beat, wordEvent, scaleManager, screen);
    spork ~ gameManager.manageGames();
    spork ~ gameManager.selectActiveGame();
    spork ~ gameManager.monitorCompleteGames();
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


// Run
main();
