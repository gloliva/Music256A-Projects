/*
    Homework 3 Sequencer
    Desc: Keyboard Input Handling
    Author: Gregg Oliva
*/


public class Key {
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


public class KeyPoller {
    // Special Characters
    "BACKSPACE" => string BACKSPACE;
    "ENTER" => string ENTER;
    "SPACE" => string SPACE;
    "PLUS" => string PLUS;
    "MINUS" => string MINUS;
    "SHIFT_BACKSPACE" => string SHIFT_BACKSPACE;

    // Arrow Keys
    "UP_ARROW" => string UP_ARROW;
    "DOWN_ARROW" => string DOWN_ARROW;
    "LEFT_ARROW" => string LEFT_ARROW;
    "RIGHT_ARROW" => string RIGHT_ARROW;

    // "Rotate" Keys
    "LEFT_BRACKET" => string LEFT_BRACKET;
    "RIGHT_BRACKET" => string RIGHT_BRACKET;

    // "Movement" Keys
    "MOVE_UP" => string MOVE_UP;
    "MOVE_DOWN" => string MOVE_DOWN;
    "MOVE_LEFT" => string MOVE_LEFT;
    "MOVE_RIGHT" => string MOVE_RIGHT;

    // Key Types
    "LetterKey" => string LETTER_KEY;
    "NumberKey" => string NUMBER_KEY;
    "SpecialKey" => string SPECIAL_KEY;

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
        if (GWindow.keyDown(GWindow.Key_Backspace) && !GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.BACKSPACE);
        if (GWindow.keyDown(GWindow.Key_Enter)) keys << new SpecialKey(this.ENTER);
        if (GWindow.keyDown(GWindow.Key_Space)) keys << new SpecialKey(this.SPACE);

        if (GWindow.keyDown(GWindow.Key_LeftBracket)) keys << new SpecialKey(this.LEFT_BRACKET);
        if (GWindow.keyDown(GWindow.Key_RightBracket)) keys << new SpecialKey(this.RIGHT_BRACKET);

        if (GWindow.keyDown(GWindow.Key_Up) && !GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.UP_ARROW);
        if (GWindow.keyDown(GWindow.Key_Down) && !GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.DOWN_ARROW);
        if (GWindow.keyDown(GWindow.Key_Left) && !GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.LEFT_ARROW);
        if (GWindow.keyDown(GWindow.Key_Right) && !GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.RIGHT_ARROW);

        return keys;
    }

    fun Key[] getKeyHeld() {
        Key keys[0];

        // Special characters while holding shift
        if (GWindow.key(GWindow.Key_Equal) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.PLUS);
        if (GWindow.key(GWindow.Key_Minus) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.MINUS);
        if (GWindow.keyDown(GWindow.Key_Backspace) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.SHIFT_BACKSPACE);

        // Arrow keys while holding shift
        if (GWindow.key(GWindow.Key_Up) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.MOVE_UP);
        if (GWindow.key(GWindow.Key_Down) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.MOVE_DOWN);
        if (GWindow.key(GWindow.Key_Left) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.MOVE_LEFT);
        if (GWindow.key(GWindow.Key_Right) && GWindow.key(GWindow.Key_LeftShift)) keys << new SpecialKey(this.MOVE_RIGHT);

        return keys;
    }
}
