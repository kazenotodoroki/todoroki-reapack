# @description Reaper To DecentSampler
# @author Todoroki
# @version 1.0
# @changelog
#   Première version
# @provides
#   [nomain] .
# @about
#   Crée une librairie DecentSampler à partir des samples exportés de REAPER.
#   Outil externe : à lancer avec Python, en dehors de REAPER.

import os
from tkinter import filedialog
from tkinter import Tk
from xml.etree.ElementTree import Element, SubElement, ElementTree, tostring
from xml.dom import minidom
import subprocess
import platform

def parse_filename(filename):
    parts = filename.rstrip('.wav').split('_')
    micro = parts[0]
    note = parts[1] if len(parts) > 1 else None
    velocity = parts[2] if len(parts) > 2 else "127"
    round_robin = parts[3] if len(parts) > 3 else "RR1"
    return micro, note, velocity, round_robin

def move_ir_files(source_folder, ir_folder):
    for file in os.listdir(source_folder):
        if file.endswith('.wav'):
            micro, note, _, _ = parse_filename(file)
            if note is None:
                if not os.path.exists(ir_folder):
                    os.makedirs(ir_folder)
                os.rename(os.path.join(source_folder, file), os.path.join(ir_folder, file))

def generate_effect(effects, effect_type, parameters):
    effect = SubElement(effects, "effect", type=effect_type)
    for param, value in parameters.items():
        effect.set(param, value)
        
def generate_dspreset_file(source_folder, destination_folder, library_name, ir_folder):
    decent_sampler = Element("DecentSampler", minVersion="1.0.0", title=library_name)
    ui = SubElement(decent_sampler, "ui", width="1000", height="600", bgImage="Images/background.jpg")
    effects = SubElement(decent_sampler, "effects")
    tab = SubElement(ui, "tab", name="main")
    groups = SubElement(decent_sampler, "groups")
    files_by_micro = {}

    for filename in os.listdir(source_folder):
        if filename.endswith(".wav"):
            micro, note, velocity, round_robin = parse_filename(filename)
            if micro not in files_by_micro:
                files_by_micro[micro] = []
            files_by_micro[micro].append((filename, note, velocity, round_robin))

    ui_width = 1000
    knob_width = 110
    y_position = 30
    num_micros = len(files_by_micro)
    knob_spacing = ui_width // (num_micros + 1)

    for idx, (micro, files) in enumerate(files_by_micro.items()):   
        x_base = knob_spacing * (idx + 1) - knob_width // 2
        
        labeled_knob = SubElement(tab, "labeled-knob", x=str(x_base), y=str(y_position), width="110", 
                                textSize="18", textColor="AA000000", trackForegroundColor="CC000000", 
                                trackBackgroundColor="66999999", label=f"Volume {micro}", 
                                type="float", minValue="0.0", maxValue="1.0", value="1.0")
        binding = SubElement(labeled_knob, "binding", type="amp", level="group", position=str(idx), 
                                parameter="AMP_VOLUME", translation="linear", 
                                translationOutputMin="0", translationOutputMax="1.0")
        
        y_adsr = y_position + 110
        adsr_parameters = [("attack", "ENV_ATTACK", "0.0", "10.0", "6.0"), 
                           ("decay", "ENV_DECAY", "0.0", "25.0", "0.0"), 
                           ("sustain", "ENV_SUSTAIN", "0.0", "1.0", "0.87"), 
                           ("release", "ENV_RELEASE", "0.0", "25.0", "15.0")]
        total_adsr_width = 4 * 10 + 3 * 15
        x_base_adjusted = x_base - total_adsr_width // 2 + knob_width // 2 

        for i, (param, env_param, min_val, max_val, default_val) in enumerate(adsr_parameters):
            x_position = x_base_adjusted + i * 25
            label = SubElement(tab, "label", x=str(x_position), y=str(y_adsr), width="15", height="15", 
                            text=param[0].upper(), textColor="AA000000", textSize="15")
            control = SubElement(tab, "control", x=str(x_position), y=str(y_adsr + 20), width="15", height="80", 
                                parameterName=param, style="linear_bar_vertical", type="float", 
                                minValue=min_val, maxValue=max_val, value=default_val, 
                                trackForegroundColor="CC000000", trackBackgroundColor="66999999")
            binding = SubElement(control, "binding", type="amp", level="group", position=str(idx), 
                                parameter=env_param, translation="linear", 
                                translationOutputMin="0", translationOutputMax="1.0")
            
    for micro, files in files_by_micro.items():
        group = SubElement(groups, "group", tags=micro, silencedByTags=micro)
        rr_groups = {}
        velocities_by_note = {}
        for filename, note, velocity, round_robin in files:
            if note not in rr_groups:
                rr_groups[note] = []
                velocities_by_note[note] = set()
            rr_groups[note].append((filename, velocity, round_robin))
            velocities_by_note[note].add(int(velocity))
        
        for note, velocities in velocities_by_note.items():
            sorted_velocities = sorted(list(velocities))
            ranges = []
            lo = 0
            for hi in sorted_velocities:
                ranges.append((lo, hi))
                lo = hi + 1
            velocities_by_note[note] = ranges

        for note, rr_files in rr_groups.items():
            if len(rr_files) > 1:
                group.set("seqMode", "random")
            for idx, (filename, velocity, round_robin) in enumerate(rr_files):
                lo_vel, hi_vel = next((r for r in velocities_by_note[note] if r[1] == int(velocity)), (0, 127))
                sample_file_path = os.path.join('Samples', filename)
                sample = SubElement(group, "sample", path=sample_file_path, rootNote=note, loNote=note, hiNote=note, loVel=str(lo_vel), hiVel=str(hi_vel))
                if round_robin:
                    sample.set("seqPosition", round_robin.replace('RR', ''))
      
    ir_files = []
    if os.path.exists(ir_folder):
        ir_files = [f for f in os.listdir(ir_folder) if f.endswith('.wav')]

    if ir_files:
        for idx, (micro, files) in enumerate(files_by_micro.items()):
            x_base = knob_spacing * (idx + 1) - knob_width // 2
            y_position_menu = 250
            y_position_knob = 290

            # IR Dropdown Menu
            ir_menu = SubElement(tab, "menu", x=str(x_base), y=str(y_position_menu),
                                width="110", height="30", requireSelection="true",
                                placeholderText="Choose...", value="1")
            for ir_file in ir_files:
                option = SubElement(ir_menu, "option", name=ir_file)
                binding = SubElement(option, "binding", type="effect", level="instrument",
                                position=str(idx), parameter="FX_IR_FILE",
                                translation="fixed_value", translationValue=f"IR/{ir_file}")

            # Mix knob 
            mix_knob = SubElement(tab, "labeled-knob", x=str(x_base), y=str(y_position_knob),
                                width="110", height="105", textSize="20", textColor="AA000000",
                                trackForegroundColor="CC000000", trackBackgroundColor="66999999",
                                label="REV Mix", type="float", minValue="0.0", maxValue="1.0", value="0.5")
            binding = SubElement(mix_knob, "binding", type="effect", level="instrument",
                                position=str(idx), parameter="FX_MIX")
            # Add IR effect for each micro
            generate_effect(effects, "convolution", {"mix": "0.5", "irFile": f"IR/{ir_files[0]}"})

    # Create DSLibraryInfo XML file
    library_info = Element("DSLibraryInfo", name=library_name, productId="945455", version="1.1.0")
    library_info_file = os.path.join(destination_folder, "DSLibraryInfo.xml")
    library_info_tree = ElementTree(library_info)
    xml_str = minidom.parseString(tostring(library_info)).toprettyxml(indent="  ")
    with open(library_info_file, "w", encoding="utf-8") as f:
        f.write(xml_str)

    # Write the DSPreset file
    dspreset_file = os.path.join(destination_folder, f"{library_name}.dspreset")
    tree = ElementTree(decent_sampler)
    xml_str = minidom.parseString(tostring(decent_sampler)).toprettyxml(indent="  ")
    with open(dspreset_file, "w", encoding="utf-8") as f:
        f.write(xml_str)

if __name__ == "__main__":
    root = Tk()
    root.withdraw()
    original_source_folder = filedialog.askdirectory(title="Select the folder to process")

    # Create folders 'Samples', 'Images' et 'IR'
    samples_folder = os.path.join(original_source_folder, 'Samples')
    images_folder = os.path.join(original_source_folder, 'Images')
    ir_folder = os.path.join(original_source_folder, 'IR')

    if not os.path.exists(samples_folder):
        os.makedirs(samples_folder)
    if not os.path.exists(images_folder):
        os.makedirs(images_folder)

    # Move files .wav in 'Samples' or 'IR'
    for file in os.listdir(original_source_folder):
        if file.endswith('.wav'):
            file_path = os.path.join(original_source_folder, file)
            micro, note, _, _ = parse_filename(file)
            if note is None:
                if not os.path.exists(ir_folder):
                    os.makedirs(ir_folder)
                os.rename(file_path, os.path.join(ir_folder, file))
            else:
                os.rename(file_path, os.path.join(samples_folder, file))

    if original_source_folder:
        library_name = input("Enter the name of the library: ")
        # Generate .dspreset and DSLibraryInfo.xml in root folder
        generate_dspreset_file(samples_folder, original_source_folder, library_name, ir_folder)

    input("Press Enter to exit...")

    # After generating the .dspreset file
    if platform.system() == "Windows":
        os.startfile(original_source_folder)
    elif platform.system() == "Darwin":  # macOS
        subprocess.Popen(["open", original_source_folder])
    else:  # Linux and other OS
        subprocess.Popen(["xdg-open", original_source_folder])
