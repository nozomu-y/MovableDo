//=============================================================================
//  MuseScore Movable Do Plugin
//
//  Copyright (C) 2022 Nozomu Yamazaki
//  based on the following code by MuseScore
//  https://github.com/musescore/MuseScore/blob/master/share/plugins/note_names/notenames.qml
//
//  License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
//=============================================================================
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1

import MuseScore 3.0
import Muse.UiComponents 1.0

MuseScore {
  
    id: root

    version: "2.0"
    description: "This plugin inserts movable do texts derived from the given tonality"
    menuPath: "Plugins.MovableDo"

    pluginType: "dialog"

    requiresScore: true

    width: exporterColumn.width + 30
    height: exporterColumn.height + 30

    //4.4 title: "Movable Do"
    Component.onCompleted: {
        if (mscoreMajorVersion >= 4 && mscoreMinorVersion <= 3) {
            title = "Movable Do";
        }
    }

    property int tonalityIndex: -1
    property int notationIndex: -1

    // Small note name size is fraction of the full font size.
    property real fontSizeMini: 0.7

    function nameChord(notes, text, small, movableDoOffset, notationIndex) {
        var tpcToTonalPitch= {
            "31": "A##",
            "19": "B",
            "7":  "Cb",
            "24": "A#",
            "12": "Bb",
            "0":  "Cbb",
            "29": "G##",
            "17": "A",
            "5":  "Bbb",
            "22": "G#",
            "10": "Ab",
            "27": "F##",
            "15": "G",
            "3":  "Abb",
            "32": "E##",
            "20": "F#",
            "8":  "Gb",
            "25": "E#",
            "13": "F",
            "1":  "Gbb",
            "30": "D##",
            "18": "E",
            "6":  "Fb",
            "23": "D#",
            "11": "Eb",
            "-1": "Fbb",
            "28": "C##",
            "16": "D",
            "4":  "Ebb",
            "33": "B##",
            "21": "C#",
            "9": "Db",
            "26": "B#",
            "14": "C",
            "2":  "Dbb"
        }
        var tonalPitchToMovableDo = {
            'A##': ['t',  'シ'],
            'A#':  ['li', 'ラ♯'],
            'G##': ['l',  'ラ'],
            'G#':  ['si', 'ソ♯'],
            'F##': ['s',  'ソ'],
            'E##': ['fi', 'ファ♯'],
            'E#':  ['f',  'ファ'],
            'D##': ['m',  'ミ'],
            'D#':  ['ri', 'レ♯'],
            'C##': ['r',  'レ'],
            'B##': ['di', 'ド♯'],
            'B#':  ['d',  'ド'],
            'B':   ['t',  'シ'],
            'Bb':  ['ta', 'シ♭'],
            'A':   ['l',  'ラ'],
            'G':   ['s',  'ソ'],
            'F#':  ['fi', 'ファ♯'],
            'F':   ['f',  'ファ'],
            'E':   ['m',  'ミ'],
            'Eb':  ['ma', 'ミ♭'],
            'D':   ['r',  'レ'],
            'C#':  ['di', 'ド♯'],
            'C':   ['d',  'ド'],
            'Cb':  ['t',  'シ'],
            'Cbb': ['ta', 'シ♭'],
            'Bbb': ['l',  'ラ'],
            'Ab':  ['lo', 'ラ♭'],
            'Abb': ['s',  'ソ'],
            'Gb':  ['se', 'ソ♭'],
            'Gbb': ['f',  'ファ'],
            'Fb':  ['m',  'ミ'],
            'Ebb': ['r',  'レ'],
            'Fbb': ['ma', 'ミ♭'],
            'Db':  ['ro', 'レ♭'],
            'Dbb': ['d',  'ド'],
        }
        var sep = "\n"
        // change to "," if you want them horizontally (anybody?)
        var oct = ""
        var name
        for (var i = 0; i < notes.length; i++) {
            if (!notes[i].visible)
                continue
            // skip invisible notes
            if (text.text)
                // only if text isn't empty
                text.text = sep + text.text
            if (small)
                text.fontSize *= fontSizeMini
            if (typeof notes[i].tpc === "undefined")
                // like for grace notes ?!?
                return
            var tonalPitch = tpcToTonalPitch[String((parseInt(notes[i].tpc) - movableDoOffset + 35 + 1) % 35 - 1)]
            name = tonalPitchToMovableDo[tonalPitch][notationIndex]

            if (notes[i].tieBack !== null) 
                // skip if the note is tied
                continue
            text.text = name + oct + text.text
        }
    }

    function renderGraceNoteNames(cursor, list, text, small, movableDoOffset, notationIndex) {
        if (list.length > 0) {
            // Check for existence.
            // Now render grace note's names...
            for (var chordNum = 0; chordNum < list.length; chordNum++) {
                // iterate through all grace chords
                var chord = list[chordNum]
                // Set note text, grace notes are shown a bit smaller
                nameChord(chord.notes, text, small, movableDoOffset, notationIndex)
                if (text.text)
                    cursor.add(text)
                // X position the note name over the grace chord
                text.offsetX = chord.posX
                switch (cursor.voice) {
                case 1:
                case 3:
                    text.placement = Placement.BELOW
                    break
                }

                // If we consume a STAFF_TEXT we must manufacture a new one.
                if (text.text)
                    text = newElement(
                                Element.STAFF_TEXT) // Make another STAFF_TEXT
            }
        }
        return text
    }

    function nameNotesMovableDo(tonalityText, notationIndex) {
        var tonalityToMovableDoOffset = {
            "C-Dur": 0,
            "G-Dur": 1,
            "D-Dur": 2,
            "A-Dur": 3,
            "E-Dur": 4,
            "H-Dur": 5,
            "Fis-Dur": 6,
            "Cis-Dur": 7,
            "F-Dur": -1,
            "B-Dur": -2,
            "Es-Dur": -3,
            "As-Dur": -4,
            "Des-Dur": -5,
            "Ges-Dur": -6,
            "Ces-Dur": -7,

            "a-moll": 0,
            "e-moll": 1,
            "h-moll": 2,
            "fis-moll": 3,
            "cis-moll": 4,
            "gis-moll": 5,
            "dis-moll": 6,
            "ais-moll": 7,
            "d-moll": -1,
            "g-moll": -2,
            "c-moll": -3,
            "f-moll": -4,
            "b-moll": -5,
            "es-moll": -6,
            "as-moll": -7
        }
        var movableDoOffset = tonalityToMovableDoOffset[tonalityText]
        var cursor = curScore.newCursor()
        var startStaff
        var endStaff
        var endTick
        var fullScore = false
        cursor.rewind(1)
        if (!cursor.segment) {
            // no selection
            fullScore = true
            startStaff = 0 // start with 1st staff
            endStaff = curScore.nstaves - 1 // and end with last
        } else {
            startStaff = cursor.staffIdx
            cursor.rewind(2)
            if (cursor.tick === 0) {
                // this happens when the selection includes
                // the last measure of the score.
                // rewind(2) goes behind the last segment (where
                // there's none) and sets tick=0
                endTick = curScore.lastSegment.tick + 1
            } else {
                endTick = cursor.tick
            }
            endStaff = cursor.staffIdx
        }
        console.log(startStaff + " - " + endStaff + " - " + endTick)

        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.rewind(1) // beginning of selection
                cursor.voice = voice
                cursor.staffIdx = staff

                if (fullScore)
                    // no selection
                    cursor.rewind(0) // beginning of score
                while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                    if (cursor.element
                            && cursor.element.type === Element.CHORD) {
                        var text = newElement(Element.STAFF_TEXT)
                        // Make a STAFF_TEXT

                        // First...we need to scan grace notes for existence and break them
                        // into their appropriate lists with the correct ordering of notes.
                        var leadingLifo = Array()
                        // List for leading grace notes
                        var trailingFifo = Array()
                        // List for trailing grace notes
                        var graceChords = cursor.element.graceNotes
                        // Build separate lists of leading and trailing grace note chords.
                        if (graceChords.length > 0) {
                            for (var chordNum = 0; chordNum < graceChords.length; chordNum++) {
                                var noteType = graceChords[chordNum].notes[0].noteType
                                if (noteType === NoteType.GRACE8_AFTER
                                        || noteType === NoteType.GRACE16_AFTER
                                        || noteType === NoteType.GRACE32_AFTER) {
                                    trailingFifo.unshift(graceChords[chordNum])
                                } else {
                                    leadingLifo.push(graceChords[chordNum])
                                }
                            }
                        }

                        // Next process the leading grace notes, should they exist...
                        text = renderGraceNoteNames(cursor, leadingLifo,
                                                    text, true, movableDoOffset, notationIndex)

                        // Now handle the note names on the main chord...
                        var notes = cursor.element.notes
                        nameChord(notes, text, false, movableDoOffset,
                                  notationIndex)
                        if (text.text)
                            cursor.add(text)

                        switch (cursor.voice) {
                        case 1:
                        case 3:
                            text.placement = Placement.BELOW
                            break
                        }

                        if (text.text)
                            text = newElement(
                                        Element.STAFF_TEXT) // Make another STAFF_TEXT object

                        // Finally process trailing grace notes if they exist...
                        text = renderGraceNoteNames(cursor, trailingFifo,
                                                    text, true, movableDoOffset, notationIndex)
                    } // end if CHORD
                    cursor.next()
                } // end while segment
            } // end for voice
        } // end for staff

        cursor.rewind(1)
        cursor.voice = 0
        cursor.staffIdx = startStaff
        if (fullScore)
            cursor.rewind(0)
        var text = newElement(Element.SYSTEM_TEXT)
        text.text = tonalityText
        text.fontSize *= 1.5
        cursor.add(text)
    }

    onRun: {
        console.log("Running Movable Do")
    } // end onRun

    Item {
        id: tonalityDialog
        anchors.fill: parent
        Rectangle {
            id: form
            width: exporterColumn.width + 30
            height: exporterColumn.height + 30
            color: (mscoreMajorVersion < 4 ? "lightgray" : "#F5F5F6")
            ColumnLayout {
                id: exporterColumn
                GridLayout {
                    id: grid
                    columns: 1
                    anchors.fill: parent
                    anchors.margins: 10
                    Label {
                        text: qsTr('調性')
                    }
                    StyledDropdown {
                        id: tonality
                        model: [
                            "C-Dur", "G-Dur", "D-Dur", "A-Dur", "E-Dur", "H-Dur", "Fis-Dur", "Cis-Dur", "F-Dur", "B-Dur", "Es-Dur", "As-Dur", "Des-Dur", "Ges-Dur", "Ces-Dur",
                            "a-moll", "e-moll", "h-moll", "fis-moll", "cis-moll", "gis-moll", "dis-moll", "ais-moll", "d-moll", "g-moll", "c-moll", "f-moll", "b-moll", "es-moll", "as-moll"
                        ]
                        currentIndex: root.tonalityIndex
                        onActivated: function(index) {
                            root.tonalityIndex = index
                        }
                    }
                    Label {
                        text: qsTr('表記')
                    }
                    StyledDropdown {
                        id: notation
                        model: ["d r m", "ド レ ミ"]
                        currentIndex: root.notationIndex
                        onActivated: function(index) {
                            root.notationIndex = index
                        }
                    }
                    FlatButton {
                        id: button
                        text: qsTr("決定")
                        onClicked: {
                            curScore.startCmd()
                            console.log(notation.currentIndex)
                            nameNotesMovableDo(tonality.currentText,
                                               notation.currentIndex)
                            curScore.endCmd()
                            tonalityDialog.visible = false
                            quit()
                        }
                    }
                }
            }
        }
    }
}
