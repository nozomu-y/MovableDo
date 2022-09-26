//=============================================================================
//  MuseScore Movable Do Plugin
//
//  Copyright (C) 2022 Nozomu Yamazaki
//  based on the following code by MuseScore
//  https://github.com/musescore/MuseScore/blob/master/share/plugins/note_names/notenames.qml
//
//  License: http://www.gnu.org/licenses/gpl.html GPL version 2 or higher
//=============================================================================

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

import MuseScore 3.0

MuseScore {
    version: "1.1"
    description: "This plugin inserts movable do texts derived from the given tonality"
    menuPath: "Plugins.MovableDo"

    // Small note name size is fraction of the full font size.
    property real fontSizeMini: 0.7

    function nameChord(notes, text, small, movableDoOffset, notationIndex) {
        var movableDo = []
        switch (notationIndex) {
        case 0:
            movableDo = ['d', 'di', 'r', 'ri', 'm', 'f', 'fi', 's', 'si', 'l', 'ta', 't']
            break
        case 1:
            movableDo = ['ド', 'ド♯', 'レ', 'レ♯', 'ミ', 'ファ', 'ファ♯', 'ソ', 'ソ♯', 'ラ', 'ラ♯', 'シ']
            break
        }
        var tpc2pitch = {
            "31": 11,
            "24": 10,
            "29": 9,
            "22": 8,
            "27": 7,
            "32": 6,
            "25": 5,
            "30": 4,
            "23": 3,
            "28": 2,
            "33": 1,
            "26": 0,
            "19": 11,
            "12": 10,
            "17": 9,
            "15": 7,
            "20": 6,
            "13": 5,
            "18": 4,
            "11": 3,
            "16": 2,
            "21": 1,
            "14": 0,
            "7": 11,
            "0": 10,
            "5": 9,
            "10": 8,
            "3": 7,
            "8": 6,
            "1": 5,
            "6": 4,
            "4": 2,
            "-1": 3,
            "9": 1,
            "2": 0
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
            name = movableDo[(tpc2pitch[notes[i].tpc] - movableDoOffset
                              + movableDo.length) % movableDo.length]

            text.text = name + oct + text.text
        }
    }

    function renderGraceNoteNames(cursor, list, text, small) {
        if (list.length > 0) {
            // Check for existence.
            // Now render grace note's names...
            for (var chordNum = 0; chordNum < list.length; chordNum++) {
                // iterate through all grace chords
                var chord = list[chordNum]
                // Set note text, grace notes are shown a bit smaller
                nameChord(chord.notes, text, small)
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
            "C-Dur / a-moll": 0,
            "G-Dur / e-moll": 7,
            "D-Dur / h-moll": 2,
            "A-Dur / fis-moll": 9,
            "E-Dur / cis-moll": 4,
            "H-Dur / gis-moll": -1,
            "Fis-Dur / dis-moll": 6,
            "Cis-Dur / ais-moll": 1,
            "F-Dur / d-moll": 5,
            "B-Dur / g-moll": -2,
            "Es-Dur / c-moll": 3,
            "As-Dur / f-moll": -4,
            "Des-Dur / b-moll": 1,
            "Ges-Dur / es-moll": 6,
            "Ces-Dur / as-moll": -1
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
                                                    text, true)

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
                                                    text, true)
                    } // end if CHORD
                    cursor.next()
                } // end while segment
            } // end for voice
        } // end for staff
    }

    onRun: {
        console.log("Running Movable Do")
    } // end onRun

    Dialog {
        id: tonalityDialog
        visible: true
        title: qsTr("Movable Do")
        width: form.width
        height: form.height
        contentItem: Rectangle {
            id: form
            width: exporterColumn.width + 30
            height: exporterColumn.height + 30
            color: "lightgray"
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
                    ComboBox {
                        id: tonality
                        model: ["C-Dur / a-moll", "G-Dur / e-moll", "D-Dur / h-moll", "A-Dur / fis-moll", "E-Dur / cis-moll", "H-Dur / gis-moll", "Fis-Dur / dis-moll", "Cis-Dur / ais-moll", "F-Dur / d-moll", "B-Dur / g-moll", "Es-Dur / c-moll", "As-Dur / f-moll", "Des-Dur / b-moll", "Ges-Dur / es-moll", "Ces-Dur / as-moll"]
                    }
                    Label {
                        text: qsTr('表記')
                    }
                    ComboBox {
                        id: notation
                        model: ["d r m", "ド レ ミ"]
                    }
                    Button {
                        id: button
                        text: qsTr("決定")
                        onClicked: {
                            curScore.startCmd()
                            console.log(notation.currentIndex)
                            nameNotesMovableDo(tonality.currentText,
                                               notation.currentIndex)
                            curScore.endCmd()
                            tonalityDialog.visible = false
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}
