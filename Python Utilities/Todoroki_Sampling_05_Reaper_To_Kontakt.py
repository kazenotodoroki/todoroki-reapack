# @description Reaper To Kontakt
# @author Todoroki
# @version 1.0
# @changelog
#   Première version
# @provides
#   [nomain] .
# @about
#   Renomme et range les samples exportés de REAPER pour Kontakt.
#   Outil externe : à lancer avec Python, en dehors de REAPER.

import os
import shutil
from collections import defaultdict
from tkinter import filedialog
from tkinter import Tk

NOTE_TO_NUMBER = {
    "C": 0,
    "C#": 1,
    "D": 2,
    "D#": 3,
    "E": 4,
    "F": 5,
    "F#": 6,
    "G": 7,
    "G#": 8,
    "A": 9,
    "A#": 10,
    "B": 11
}

def note_to_midi(note):
    note_name = note[:-1]
    octave = int(note[-1])
    midi_number = NOTE_TO_NUMBER[note_name] + (octave + 2) * 12
    return f"{midi_number:03}"

def parse_filename(filename):
    """Parse the filename into its components: instrument, note, velocity, and round robin."""
    parts = filename.rstrip('.wav').split('_')
    instrument = parts[0]
    
    note_parts = parts[1] if len(parts) > 1 else None
    if note_parts:
        note = note_to_midi(note_parts)
    else:
        note = None

    velocity = parts[2] if len(parts) > 2 else None
    round_robin = parts[3] if len(parts) > 3 else None
    return instrument, note, velocity, round_robin

def move_files(source_folder):
    """Organize and move files based on their instrument and round robin group."""
    files_by_instrument = defaultdict(list)

    # Group files by instrument
    for filename in os.listdir(source_folder):
        if filename.endswith(".wav"):
            instrument, note, velocity, round_robin = parse_filename(filename)
            files_by_instrument[instrument].append((filename, round_robin, note))

    # Create folders and move files
    for instrument, files in files_by_instrument.items():
        if len(files_by_instrument) > 1:
            instrument_folder = os.path.join(source_folder, instrument)
            if not os.path.exists(instrument_folder):
                os.makedirs(instrument_folder)
        else:
            instrument_folder = source_folder

        rr_groups = defaultdict(list)
        for filename, round_robin, note in files:
            rr_groups[round_robin].append((filename, note))

        for rr, files in rr_groups.items():
            if rr:
                rr_number = rr.replace('RR', '').replace('.wav', '')
                rr_folder_name = f'group_{int(rr_number):02d}'
                rr_folder = os.path.join(instrument_folder, rr_folder_name)
                if not os.path.exists(rr_folder):
                    os.makedirs(rr_folder)
            else:
                rr_folder = instrument_folder

            for filename, note in files:
                if note:
                    original_note = filename.rstrip('.wav').split('_')[1]
                    new_filename = filename.replace(original_note, note)
                else:
                    new_filename = filename
                shutil.move(os.path.join(source_folder, filename), os.path.join(rr_folder, new_filename))

if __name__ == "__main__":
    root = Tk()
    root.withdraw()  # We don't need a full Tk window, so remove the main window
    source_folder = filedialog.askdirectory(title="Select the folder to process")  # Display the folder selection dialog
    if source_folder:  # If a folder was selected
        move_files(source_folder)
    input("Press Enter to exit...")
