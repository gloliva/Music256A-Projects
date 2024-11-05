/*
    Homework 3 Sequencer
    Desc: UI
    Author: Gregg Oliva
*/


public class GameMatrixUI extends GGen {
    GPlane box;
    GText row;
    GText cross;
    GText col;
    GText clock;
    GText divider;

    fun @construct() {
        // Scale
        2. => box.scaX;
        @(0.6, 0.6, 0.6) => row.sca;
        @(0.6, 0.6, 0.6) => cross.sca;
        @(0.6, 0.6, 0.6) => col.sca;
        @(0.2, 0.2, 0.2) => clock.sca;
        @(0.2, 0.2, 0.2) => divider.sca;
        @(0.5, 0.5, 0.5) => this.sca;

        // Text
        "." => row.text;
        "x" => cross.text;
        "." => col.text;
        "Beat Div" => clock.text;
        "." => divider.text;

        // Text color
        @(0., 0., 0., 1.) => row.color;
        @(0., 0., 0., 1.) => cross.color;
        @(0., 0., 0., 1.) => col.color;
        @(0., 0., 0., 1.) => clock.color;
        @(0., 0., 0., 1.) => divider.color;

        // Positions
        @(-0.6, 0.2, 0.1) => row.pos;
        @(0., 0.2, 0.1) => cross.pos;
        @(0.6, 0.2, 0.1) => col.pos;
        @(-0.4, -0.3, 0.1) => clock.pos;
        @(0.62, -0.3, 0.1) => divider.pos;

        1. => this.posZ;

        // Name
        "Matrix UI" => this.name;
        "Background" => this.box.name;
        "Row #" => this.row.name;
        "Col #" => this.col.name;
        "X" => this.cross.name;
        "Clock" => this.clock.name;
        "Beat divider" => this.divider.name;

        // Connections
        row --> this;
        cross --> this;
        col --> this;
        clock --> this;
        divider --> this;
        box --> this --> GG.scene();
    }

    fun void updateRow(string row) {
        row => this.row.text;
    }

    fun void updateCol(string col) {
        col => this.col.text;
    }

    fun void updateDivider(string divider) {
        divider => this.divider.text;
    }

    fun void reset() {
        "." => this.row.text;
        "." => this.col.text;
        "." => this.divider.text;
    }

    fun void setPos(GCamera cam, vec2 screenSize) {
        cam.posZ() - this.posZ() => float depth;
        @(screenSize.x + 100, screenSize.y - 60) => vec2 screenPos;
        cam.screenCoordToWorldPos(screenPos, depth) => vec3 worldPos;
        worldPos => this.pos;
    }
}


public class ChordleUI extends GGen {
    GPlane box;
    GText text;

    fun @construct() {
        // Text
        "Chordle" => text.text;
        @(0., 0., 0., 1.) => text.color;

        // Scale
        5. => box.scaX;
        0.5 => this.sca;

        // Pos
        0.1 => text.posZ;

        // Name
        "ChordleUI" => this.name;
        "Title" => this.text.name;
        "Background" => this.box.name;

        // Connections
        text --> this;
        box --> this --> GG.scene();
    }

    fun void setPos(GCamera cam, vec2 screenSize) {
        cam.posZ() - this.posZ() => float depth;
        @(screenSize.x / 2., 50) => vec2 screenPos;
        cam.screenCoordToWorldPos(screenPos, depth) => vec3 worldPos;
        worldPos => this.pos;
    }
}
