/*
    Homework 3 Sequencer
    Desc: Background
    Author: Gregg Oliva
*/


// Imports
@import "hw3_events.ck"  // Event Handling


public class BackgroundLetter extends GGen {
    // Graphics objects
    GCube border;
    GPlane panels[6];
    GText letters[6];

    // Colors
    [
        Color.RED,
        Color.GREEN,
        Color.BLUE,
        Color.YELLOW,
        Color.VIOLET,
        Color.PINK
    ] @=> vec3 colors[];
    vec3 letterColor;
    vec3 panelColor;

    // State Variables
    int active;
    float endY;

    // Movement and Rotation
    float rotXSpeed;
    float rotYSpeed;
    float rotZSpeed;
    int xDir;
    int yDir;
    int zDir;
    float moveSpeed;

    fun @construct(string letter) {
        // Color
        Math.random2(0, colors.size()) => int colorIdx;
        colors[colorIdx] * 6. => this.panelColor;
        Color.BLACK => this.letterColor;

        // Panel Handling
        this.initPanels();

        // Text Handling
        this.initText(letter);

        // Init border
        Color.DARKGRAY => border.color;

        // State
        1 => this.active;
        -10. => this.endY;

        // Movement and Rotation
        this.calculateRotation();
        this.calculateMoveSpeed();

        // Names
        "Border" => this.border.name;
        "LetterFrequencyBox" => this.name;

        // Connections
        this.border --> this --> GG.scene();
    }

    fun vec4 getLetterColor() {
        return @(this.letterColor.x, this.letterColor.y, this.letterColor.z, 1.);
    }

    fun void initText(string text) {
        for (int idx; idx < this.letters.size(); idx++) {
            this.letters[idx] @=> GText letter;
            text => letter.text;
            this.getLetterColor() => letter.color;
            0.01 => letter.posZ;
            "Text" => letter.name;
            letter --> this.panels[idx];
        }
    }

    fun void initPanels() {
        // Front
        this.panels[0] @=> GPlane panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        0.501 => panel.posZ;
        this.panelColor=> panel.color;
        "Front panel" => panel.name;
        panel --> this;

        // Back
        this.panels[1] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        -0.501 => panel.posZ;
        Math.PI  => panel.rotateY;
        this.panelColor=> panel.color;
        "Back panel" => panel.name;
        panel --> this;

        // Right
        this.panels[2] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        0.501 => panel.posX;
        Math.PI / 2 => panel.rotateY;
        this.panelColor=> panel.color;
        "Right panel" => panel.name;
        panel --> this;

        // Left
        this.panels[3] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        -0.501 => panel.posX;
        -Math.PI / 2 => panel.rotateY;
        this.panelColor=> panel.color;
        "Left panel" => panel.name;
        panel --> this;

        // Top
        this.panels[4] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        0.501 => panel.posY;
        -Math.PI / 2 => panel.rotateX;
        this.panelColor=> panel.color;
        "Top panel" => panel.name;
        panel --> this;

        // Bottom
        this.panels[5] @=> panel;
        @(0.95, 0.95, 0.95) => panel.sca;
        -0.501 => panel.posY;
        Math.PI / 2 => panel.rotateX;
        this.panelColor=> panel.color;
        "Bottom panel" => panel.name;
        panel --> this;
    }

    fun void calculateRotation() {
        Math.random2f(0.25, 5.) => this.rotXSpeed;
        Math.random2f(0.25, 5.) => this.rotYSpeed;
        Math.random2f(0.25, 5.) => this.rotZSpeed;

        Math.random2(-1, 1)  => this.xDir;
        Math.random2(-1, 1)  => this.yDir;
        Math.random2(-1, 1)  => this.zDir;
    }

    fun void calculateMoveSpeed() {
        vec3 rotSpeed;
        rotSpeed.set(this.rotXSpeed, this.rotYSpeed, this.rotZSpeed);

        @(0.25, 0.25, 0.25) => vec3 minRot;
        @(5., 5., 5.) => vec3 maxRot;

        Std.scalef(rotSpeed.magnitude(), minRot.magnitude(), maxRot.magnitude(), 5., 0.25) => this.moveSpeed;
    }

    fun void setPos(float x, float y, float z) {
        @(x, y, z) => this.pos;
    }

    fun void rotate() {
        while ( this.active ) {
            this.xDir * ( Math.PI / this.rotXSpeed ) * GG.dt() => this.rotateX;
            this.yDir * ( Math.PI / this.rotYSpeed ) * GG.dt() => this.rotateY;
            this.zDir * ( Math.PI / this.rotZSpeed ) * GG.dt() => this.rotateZ;
            GG.nextFrame() => now;
        }
    }

    fun void move() {
        while ( this.posY() > this.endY ) {
            -1 * this.moveSpeed * GG.dt() => this.translateY;
            GG.nextFrame() => now;
        }

        0 => this.active;
        this --< GG.scene();
    }
}


public class BackgroundManager {
    string letters[0];
    int size;

    Event @ beat;
    WordEvent @ wordEvent;
    int spawnCount;
    int globalCount;

    fun @construct(Event beat, WordEvent wordEvent) {
        beat @=> this.beat;
        wordEvent @=> this.wordEvent;
        0 => this.size;
    }

    fun void addLetters() {
        string currWord;
        while (true) {
            this.wordEvent => now;
            this.wordEvent.word() => currWord;
            for (int charIdx; charIdx < currWord.length(); charIdx++) {
                currWord.substring(charIdx, 1) => string letter;
                this.letters << letter;
                this.size++;
            }
        }
    }

    fun void counter() {
        while (true) {
            this.beat => now;
            this.globalCount++;
            <<< this.globalCount >>>;
        }
    }

    fun void spawnBackgroundLetters() {
        // Wait until letters get added
        while (size < 1) {
            GG.nextFrame() => now;
        }

        // Periodically spawn background letters
        // Spawn rate increases as size increases
        int spawnDiff;
        while (true) {
            Std.scalef(this.size, 1., 100., 5., 4.)$int => spawnDiff;
            while (this.globalCount - spawnDiff > this.spawnCount) {
                GG.nextFrame() => now;
            }

            // Instantiate new BackgroundLetter;
            this.letters[Math.random2(0, this.size - 1)] => string letter;
            BackgroundLetter bl(letter);
            bl.setPos(Math.random2(-10, 10), 8, -12);
            spork ~ bl.rotate();
            spork ~ bl.move();

            // Update spawn count
            this.globalCount => this.spawnCount;
            GG.nextFrame() => now;
        }
    }
}
