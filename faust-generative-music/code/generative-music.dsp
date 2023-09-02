import("stdfaust.lib");

// Metronome
bpm = hslider("bpm", 40, 40, 240, 1);
metronome = ba.beat(bpm);

// Sequencer
steps = 16;
sequencer = metronome : ba.pulse_countup_loop(steps-1, 1) : hbargraph("seq",0,steps-1);

// Random Trigger
randomtrig = 1 : *(no.noise : *(0.5) : +(0.5) : ba.sAndH(metronome) < probability : hbargraph("trigger", 0, 1))
with {
    probability = hslider("trigger probability", 0.3, 0, 1, 0.01);
};

// Drone
env = en.arfe(20, 20, 0.1, randomtrig == 1);
voice(freq, detune, mix) = os.osc(freq), os.square(freq*2)*0.3, os.triangle(freq+detune) :> *(mix);
drone = 
    voice(root, 0, voicelfo2),
    voice(fifth, 0, 1),
    voice(major6, 0, 1),
    voice(minor7, 1, 1-voicelfo),
    voice(root*2, 0, voicelfo),
    voice(octavefourth, 2, voicelfo2) 
:> ve.moog_vcf(0.4, 1100) : *(env) : *(mix)
with {
    root = ba.midikey2hz(48); // C3
    fifth = ba.midikey2hz(55);
    major6 = ba.midikey2hz(57);
    minor7 = ba.midikey2hz(58);
    octavefourth = ba.midikey2hz(65);
    voicelfo = os.lf_triangle(0.08);
    voicelfo2 = os.lf_triangle(0.05);
    mix = hslider("drone volume", 0.2, 0, 1, 0.1);
};

// Leads
randomnote = root
    : +(root : *(no.noise : *(0.5) : +(0.5) : ba.sAndH(metronome)))
    : qu.quantize(root, qu.dorian)
with {
    root = ba.midikey2hz(72); // C5
};
trigger1 = sequencer%2==0 : *(randomtrig) : hbargraph("trigger1", 0, 1);
trigger2 = sequencer%2==1 : *(randomtrig) : hbargraph("trigger2", 0, 1);
lead1 = os.sawtooth(randomnote) : ve.moog_vcf(0.9, 1000) : *(en.ar(0.01, 0.3, trigger1))
with {
    mix = hslider("lead1 volume", 0.4, 0, 1, 0.1);
};
lead2 = os.square(randomnote*2) : ve.moog_vcf(0.9, 1000) : *(en.ar(0.01, 0.3, trigger2))
with {
    mix = hslider("lead2 volume", 0.4, 0, 1, 0.1);
};

// Bass
bass = os.osc(root), os.square(root*2) :> ve.moog_vcf(0.1, 700) : *(en.ar(2, 16, sequencer==8)) : *(mix)
with {
    root = ba.midikey2hz(36); // C2
    mix = hslider("bass volume", 0.1, 0, 1, 0.1);
};

// Reverb
reverb = re.greyhole(28, 0.7, 2.6, 0.6, 0.4, 0.1, 1.7);


// Main process
process = drone : +(bass) <: +(lead1), +(lead2) : reverb : (*(vol) : aa.hardclip : aa.cubic1), (*(vol) : aa.hardclip : aa.cubic1)
with {
    vol = hslider("volumne", 0.4, 0, 1, 0.1);
};
