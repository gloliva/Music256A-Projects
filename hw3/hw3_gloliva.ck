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
Color.WHITE => GG.scene().backgroundColor;


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
        if (row >= this.numRows) {
            // BAD
            return;
        }

        if (col >= this.numCols) {
            // BAD
            return;
        }

        this.grid[row][col] @=> LetterBox lb;
        lb.setLetter(text);
    }

    fun void removeLetter(int row, int col) {
        if (row >= this.numRows) {
            // BAD
            return;
        }

        if (col >= this.numCols) {
            // BAD
            return;
        }

        this.grid[row][col] @=> LetterBox lb;
        lb.removeLetter();
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
fun void test(ChordleGrid grid) {
    repeat(120) {
        GG.nextFrame() => now;
    }

    grid.grid[0][1].rotate();
    grid.grid[0][1].setGreen();

}


ChordleGrid grid(6, 5);
grid.setLetter("X", 0, 0);
grid.setLetter("X", 0, 1);

spork ~ test(grid);
main();
