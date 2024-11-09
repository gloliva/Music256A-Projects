/*
    Homework 3 Sequencer
    Desc: Background
    Author: Gregg Oliva
*/


public class LetterFrequencyBox extends GGen {
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


    fun @construct(string letter) {
        // Color
        Math.random2(0, colors.size()) => int colorIdx;
        colors[colorIdx] => this.panelColor;
        @(6., 6., 6.) => this.letterColor;

        // Panel Handling
        this.initPanels();

        // Text Handling
        this.initText(letter);

        // Init border
        Color.DARKGRAY => border.color;

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
}


public class BubbleManager {

}
