#!/usr/bin/env python3
"""Generate a real, topic-tagged PHY 104 question bank.

Source material:
  100level/second semester/phy104/PHY 104 complete.pdf
  100level/second semester/phy104/PHY 104 LECTURE NOTE(3)_013225.pdf

The scanned "PHY 104 Questions.pdf" is image-only and is not used here.

Run from the repository root:
    python3 scripts/generate_phy104.py
"""

from __future__ import annotations

import json
import math
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/questions/phy104.json"
VERSION = "2.0.0"
COURSE_ID = "phy104"
COURSE_NAME = "Vibration, Waves & Optics"

random.seed(104)

SUPERSCRIPT = {1: "¹", 2: "²", 3: "³", 4: "⁴", 5: "⁵"}

TOPICS = [
    "Simple Harmonic Motion",
    "Damped, Forced & Coupled Oscillations",
    "Wave Properties & Equations",
    "Superposition, Interference & Diffraction",
    "Sound Intensity & Perception",
    "Doppler Effect, Beats & Echoes",
    "Waves in Pipes & Resonance",
    "Geometrical Optics",
    "Wave Optics & Polarization",
]


def fmt(value) -> str:
    """Compact, readable number formatting for stems and options."""
    if isinstance(value, str):
        return value
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float) and value.is_integer() and abs(value) < 1_000_000:
        return str(int(value))
    return f"{value:.4g}"


def build_options(correct: str, distractors: list[str]):
    options = [correct, *distractors]
    if len(set(options)) != len(options):
        raise ValueError(f"Duplicate option in: {options}")
    random.shuffle(options)
    return options, options.index(correct)


def numeric_options(correct: float, unit: str):
    """Build four plausible numeric options with a shuffled correct index."""
    correct_text = f"{fmt(correct)}{unit}"
    delta = abs(correct) * 0.1 or 0.1
    candidates = [
        correct * 2,
        correct / 2,
        correct * 1.25,
        correct * 0.75,
        correct * 1.1,
        correct * 0.9,
        correct * 3,
        correct / 3,
        correct * 1.5,
        correct * (2 / 3),
        correct + delta,
        correct - delta,
        correct + 2 * delta,
        correct - 2 * delta,
    ]

    wrong_values: list[float] = []
    wrong_texts: list[str] = []
    for value in candidates:
        if correct > 0 and value <= 0:
            continue
        if math.isclose(value, correct, rel_tol=1e-6, abs_tol=1e-12):
            continue
        if any(math.isclose(value, w, rel_tol=1e-6, abs_tol=1e-12) for w in wrong_values):
            continue
        text = f"{fmt(value)}{unit}"
        if text == correct_text or text in wrong_texts:
            continue
        wrong_values.append(value)
        wrong_texts.append(text)
        if len(wrong_texts) == 3:
            break

    if len(wrong_texts) != 3:
        raise ValueError(f"Could not build three distractors for {correct}{unit}")

    options = [correct_text, *wrong_texts]
    random.shuffle(options)
    return options, options.index(correct_text)


# (topic, stem, correct option, three distractors, explanation, difficulty)
CONCEPTUAL = [
    (
        "Simple Harmonic Motion",
        "In simple harmonic motion, the restoring force is",
        "proportional to displacement and directed toward the mean position",
        ["proportional to velocity", "constant in magnitude", "proportional to the square of displacement"],
        "SHM is defined by F = -kx: the force is linear in displacement and always restores toward equilibrium.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "The acceleration of a particle executing SHM is given by",
        "a = -ω²y",
        ["a = ω²y", "a = -ωy", "a = -ω²v"],
        "Differentiating y = a sin(ωt) twice gives a = -ω²y.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "At the mean position of an SHM oscillator,",
        "kinetic energy is maximum and potential energy is zero",
        ["potential energy is maximum and kinetic energy is zero", "both energies are zero", "both energies are maximum"],
        "At y = 0 the speed is greatest, so K = ½mω²a² and U = 0.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "At an extreme position of an SHM oscillator,",
        "potential energy is maximum and kinetic energy is zero",
        ["kinetic energy is maximum and potential energy is zero", "both energies are zero", "the acceleration is zero"],
        "At y = ±a the speed is zero, so U = ½mω²a² and K = 0.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "The total mechanical energy of an SHM oscillator is proportional to",
        "the square of the amplitude",
        ["the amplitude only", "the displacement from equilibrium", "the square of the instantaneous velocity"],
        "E = ½mω²a², so total energy scales with a².",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "The period of a simple pendulum depends on",
        "its length and the gravitational acceleration",
        ["its mass and amplitude", "its mass only", "its amplitude only"],
        "T = 2π√(l/g); mass does not appear in the ideal simple-pendulum formula.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "For a spring-mass oscillator, increasing the attached mass",
        "increases the period",
        ["decreases the period", "leaves the period unchanged", "doubles the frequency"],
        "T = 2π√(m/k), so a larger m gives a longer period.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "For a spring-mass oscillator, increasing the spring constant",
        "decreases the period",
        ["increases the period", "leaves the period unchanged", "makes the motion non-periodic"],
        "T = 2π√(m/k), so a stiffer spring gives a shorter period.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "The phase of a vibrating particle determines its",
        "position and direction of motion relative to the mean position",
        ["mass and spring constant", "total energy only", "amplitude only"],
        "Phase is the argument of the sine or cosine function and fixes the state of motion.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "Angular frequency ω is related to ordinary frequency f by",
        "ω = 2πf",
        ["ω = f/2π", "ω = 2π/f", "ω = f²"],
        "One cycle corresponds to 2π radians, so ω = 2πf.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "The SI unit of angular frequency is",
        "rad s⁻¹",
        ["m s⁻¹", "N m⁻¹", "kg m⁻³"],
        "Angular frequency is measured in radians per second.",
        1,
    ),
    (
        "Simple Harmonic Motion",
        "A non-harmonic oscillation is",
        "a combination of two or more harmonic oscillations",
        ["a single sine or cosine function", "a motion with no restoring force", "a wave that needs no medium"],
        "The lecture notes define non-harmonic oscillation as a sum of two or more harmonic terms.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "Damped oscillations are characterised by",
        "amplitude decreasing exponentially with time",
        ["amplitude increasing with time", "constant energy in spite of friction", "frequency becoming zero immediately"],
        "Damping forces such as friction remove energy, so amplitude decays exponentially.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "Resonance occurs when",
        "the driving frequency equals the natural frequency",
        ["the damping is zero only", "the amplitude is zero", "the driving frequency is twice the natural frequency"],
        "At resonance the external force matches the natural frequency and the response is largest.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "An ideal free oscillation has",
        "constant amplitude, frequency and energy",
        ["exponentially decaying amplitude", "an external periodic driving force", "a continuously changing natural frequency"],
        "Free oscillations proceed at the natural frequency with no energy loss in the ideal case.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "Forced oscillations are sustained by",
        "an external periodic force",
        ["the absence of any medium", "total internal reflection", "a polarizer"],
        "A forced oscillator is driven by an external periodic force.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "Coupled oscillations involve",
        "two or more linked particles whose motions influence one another",
        ["a single isolated mass on a spring", "light passing through a prism", "sound in a vacuum"],
        "Coupled SHM links two or more particles, e.g. masses joined by a spring.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "Maintained oscillations compensate energy losses by",
        "supplying energy from an external source",
        ["removing the restoring force", "increasing the damping", "making the medium a vacuum"],
        "A maintained oscillator receives energy from outside to replace dissipated energy.",
        1,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "Normal modes are best described as",
        "collective patterns of motion in a coupled system",
        ["random noise in a room", "a single ray of light", "the threshold of hearing"],
        "Normal modes are the characteristic coordinated motions of coupled oscillators.",
        2,
    ),
    (
        "Damped, Forced & Coupled Oscillations",
        "The Q value of a resonant system is associated with",
        "the sharpness of its power response curve",
        ["the speed of sound in a vacuum", "the refractive index of glass", "the beat frequency of two notes"],
        "The course outline links Q values with resonance and power response curves.",
        2,
    ),
    (
        "Wave Properties & Equations",
        "A wave transfers",
        "energy without permanently displacing the medium",
        ["matter from source to receiver", "only electric charge", "mass but not energy"],
        "A wave is a disturbance that carries energy while the medium oscillates about equilibrium.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "Mechanical waves",
        "require a material medium for propagation",
        ["travel fastest in a vacuum", "are always transverse", "do not carry energy"],
        "Water waves, sound and waves on a string need a material medium.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "Electromagnetic waves",
        "do not require a material medium",
        ["require air to propagate", "are longitudinal only", "cannot travel through a vacuum"],
        "Light, radio waves, X-rays and gamma rays propagate without a material medium.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "In a transverse wave, the vibration of the medium is",
        "perpendicular to the direction of travel",
        ["parallel to the direction of travel", "circular about the source", "absent"],
        "Transverse waves have particle motion at right angles to propagation.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "In a longitudinal wave, the vibration of the medium is",
        "parallel to the direction of travel",
        ["perpendicular to the direction of travel", "confined to one plane only", "zero"],
        "Longitudinal waves have particle motion along the direction of propagation.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "For a sinusoidal wave y = A sin(kx - ωt), the wave speed is",
        "ω/k",
        ["k/ω", "Aω", "2π/ω"],
        "The phase velocity of y = A sin(kx - ωt) is v = ω/k.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "The angular wave number k is related to wavelength λ by",
        "k = 2π/λ",
        ["k = λ/2π", "k = 2πλ", "k = 1/λ²"],
        "One wavelength corresponds to a phase change of 2π radians.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "For any periodic wave, wave speed v, frequency f and wavelength λ satisfy",
        "v = fλ",
        ["v = f/λ", "v = λ/f", "v = f²λ"],
        "One wavelength passes per period, so speed equals frequency times wavelength.",
        1,
    ),
    (
        "Wave Properties & Equations",
        "Phase velocity and group velocity",
        "are generally different in a dispersive medium",
        ["are always identical", "are both zero in a vacuum", "apply only to sound in pipes"],
        "Dispersion makes the phase and group velocities differ; the course outline lists both.",
        2,
    ),
    (
        "Wave Properties & Equations",
        "The wave equation in two and three dimensions generalises",
        "the one-dimensional wave equation to higher-dimensional propagation",
        ["Snell's law", "the lens formula", "the decibel scale"],
        "The outline explicitly includes 2-D and 3-D wave equations.",
        2,
    ),
    (
        "Wave Properties & Equations",
        "Waves at interfaces are mainly studied in terms of",
        "reflection, transmission, energy and power",
        ["radioactive decay", "chemical equilibrium", "polarization by a Polaroid only"],
        "The course outline lists waves at interfaces together with energy and power of waves.",
        2,
    ),
    (
        "Superposition, Interference & Diffraction",
        "The principle of superposition states that the resultant displacement is",
        "the algebraic sum of the individual wave displacements",
        ["the product of the individual displacements", "always zero", "the largest displacement only"],
        "For linear waves, yR = y1 + y2 + ...",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Waves that obey the principle of superposition are called",
        "linear waves",
        ["non-linear waves", "stationary waves", "polarized waves"],
        "The lecture note calls waves that obey superposition linear waves.",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Constructive interference occurs when superposed displacements are",
        "in the same direction",
        ["in opposite directions", "at right angles", "completely absent"],
        "Same-direction displacements add to give a larger resultant.",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Destructive interference occurs when superposed displacements are",
        "in opposite directions",
        ["in the same direction", "both zero", "parallel to the wavefront"],
        "Opposite displacements partially or completely cancel.",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Diffraction is the",
        "bending of waves around obstacles or apertures",
        ["complete absorption of a wave", "change of frequency at a boundary", "production of polarized light"],
        "The lecture note defines diffraction as bending around corners of an obstacle or aperture.",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Diffraction becomes more pronounced when",
        "the aperture is small compared with the wavelength",
        ["the aperture is very large compared with the wavelength", "the wave speed is zero", "the medium is a vacuum"],
        "A smaller aperture relative to λ gives stronger spreading.",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Polarization is possible only for",
        "transverse waves",
        ["longitudinal waves", "sound waves in air", "all mechanical waves"],
        "Polarization confines vibration to one plane, which requires transverse vibration.",
        1,
    ),
    (
        "Superposition, Interference & Diffraction",
        "Polarization of light is evidence that light is",
        "transverse in nature",
        ["longitudinal in nature", "a stream of particles only", "unable to interfere"],
        "Only transverse waves can be polarized, so polarized light proves transverse character.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "Sound waves in air are",
        "longitudinal mechanical waves",
        ["transverse electromagnetic waves", "polarized light waves", "waves that need no medium"],
        "Sound requires a medium and its particle vibration is along the propagation direction.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "Sound cannot propagate through",
        "a vacuum",
        ["a solid", "a liquid", "a gas"],
        "Sound is mechanical and needs a material medium.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The speed of sound is generally greatest in",
        "solids",
        ["gases", "liquids", "a vacuum"],
        "The notes give roughly 6000 m/s in solids, 1480 m/s in liquids and 330-343 m/s in air.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "Sound intensity is defined as",
        "power per unit area perpendicular to the wave",
        ["energy multiplied by time", "frequency divided by wavelength", "pressure divided by density"],
        "I = Power/Area, with units W/m².",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The decibel scale is",
        "logarithmic",
        ["linear", "quadratic", "exponential in time"],
        "β = 10 log10(I/I0) is a logarithmic measure.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The standard threshold of hearing intensity I0 is",
        "10⁻¹² W m⁻²",
        ["1 W m⁻²", "10¹² W m⁻²", "10⁻² W m⁻²"],
        "The notes use I0 = 10⁻¹² W/m² as the reference intensity.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The pitch of a musical note mainly depends on its",
        "frequency",
        ["intensity", "overtone structure", "speed in the medium"],
        "Higher frequency gives higher pitch.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The loudness of a sound mainly depends on its",
        "intensity",
        ["frequency only", "wavelength only", "polarization"],
        "Loudness is the sensation associated with intensity, which scales with amplitude squared.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The quality or timbre of a note depends on",
        "the overtones present",
        ["its speed in air", "the refractive index", "the critical angle"],
        "Quality lets the ear distinguish notes of the same pitch and loudness.",
        1,
    ),
    (
        "Sound Intensity & Perception",
        "The approximate audible frequency range for humans quoted in the notes is",
        "15 - 20,000 Hz",
        ["1 - 100 Hz", "100,000 - 1,000,000 Hz", "1 - 10 kHz only"],
        "The lecture note gives 15 - 20,000 Hz for human audio frequency.",
        1,
    ),
    (
        "Doppler Effect, Beats & Echoes",
        "The Doppler effect is a change in observed frequency caused by",
        "relative motion between source and observer",
        ["a change of colour only", "polarization of the wave", "the medium becoming a vacuum"],
        "Relative motion changes the apparent frequency of a wave.",
        1,
    ),
    (
        "Doppler Effect, Beats & Echoes",
        "An echo is produced by",
        "reflection of sound",
        ["refraction of sound", "diffraction of light", "total internal reflection"],
        "Echoes are reflected sound waves returning to the listener.",
        1,
    ),
    (
        "Doppler Effect, Beats & Echoes",
        "Beats are heard when",
        "two notes of slightly different frequencies sound together",
        ["a single pure tone is played", "sound travels through a vacuum", "light is polarized"],
        "Beats are periodic loudness variations from superposing close frequencies.",
        1,
    ),
    (
        "Doppler Effect, Beats & Echoes",
        "The beat frequency of two notes f1 and f2 is",
        "|f1 - f2|",
        ["f1 + f2", "f1 × f2", "(f1 + f2)/2"],
        "The notes give fbeat = f1 - f2, i.e. the magnitude of the difference.",
        1,
    ),
    (
        "Doppler Effect, Beats & Echoes",
        "Reverberation is the persistence of sound",
        "after the source has stopped",
        ["before the source starts", "only in a vacuum", "only for ultrasonic waves"],
        "The notes define reverberation as persistence of sound after the source ceases.",
        1,
    ),
    (
        "Waves in Pipes & Resonance",
        "A closed pipe supports",
        "only odd harmonics",
        ["only even harmonics", "no harmonics", "all harmonics equally"],
        "The notes derive f0, 3f0, 5f0, ... for a closed pipe.",
        1,
    ),
    (
        "Waves in Pipes & Resonance",
        "An open pipe supports",
        "all harmonics",
        ["only odd harmonics", "only the fundamental", "no standing waves"],
        "The notes derive f0, 2f0, 3f0, ... for an open pipe.",
        1,
    ),
    (
        "Waves in Pipes & Resonance",
        "In a resonance tube, the end correction arises because",
        "the antinode is slightly above the open end",
        ["the node is below the closed end", "the tuning fork changes frequency", "air becomes a vacuum"],
        "The notes state that the antinode at the top does not exactly coincide with the tube opening.",
        2,
    ),
    (
        "Waves in Pipes & Resonance",
        "At the closed end of a vibrating air column there is always",
        "a displacement node",
        ["a displacement antinode", "a pressure node", "total internal reflection"],
        "Air particles cannot move at a closed end, giving a node.",
        1,
    ),
    (
        "Geometrical Optics",
        "The speed of light in vacuum is approximately",
        "3.0 × 10⁸ m s⁻¹",
        ["3.0 × 10⁶ m s⁻¹", "340 m s⁻¹", "1.0 × 10¹² m s⁻¹"],
        "The lecture note gives C ≈ 3.0 × 10⁸ m/s.",
        1,
    ),
    (
        "Geometrical Optics",
        "For light, speed c, frequency f and wavelength λ satisfy",
        "c = fλ",
        ["c = f/λ", "c = λ/f", "c = f²λ"],
        "The lecture note states C = fλ.",
        1,
    ),
    (
        "Geometrical Optics",
        "The law of reflection states that",
        "the angle of incidence equals the angle of reflection",
        ["the angle of incidence is twice the angle of reflection", "light always bends toward the normal", "frequency changes on reflection"],
        "Specular reflection has equal incident and reflected angles measured from the normal.",
        1,
    ),
    (
        "Geometrical Optics",
        "Refraction occurs because light",
        "changes speed when it enters a different medium",
        ["stops at the interface", "changes frequency at the interface", "becomes longitudinal"],
        "The notes describe refraction as a change in speed from one medium to another.",
        1,
    ),
    (
        "Geometrical Optics",
        "Snell's law states that for a given pair of media",
        "sin i / sin r is constant",
        ["sin i × sin r is constant", "i + r is constant", "i - r is constant"],
        "The second law of refraction is η = sin i / sin r.",
        1,
    ),
    (
        "Geometrical Optics",
        "Total internal reflection requires light to travel",
        "from a higher to a lower refractive index above the critical angle",
        ["from a lower to a higher refractive index", "only through a vacuum", "parallel to the normal"],
        "Beyond the critical angle, refraction ceases and reflection becomes total.",
        2,
    ),
    (
        "Geometrical Optics",
        "A convex lens is",
        "converging",
        ["diverging", "always plane", "opaque to light"],
        "The notes describe convex lenses as converging lenses.",
        1,
    ),
    (
        "Geometrical Optics",
        "A concave lens is",
        "diverging",
        ["converging", "always converging for real objects", "a source of total internal reflection"],
        "The notes describe concave lenses as diverging lenses.",
        1,
    ),
    (
        "Geometrical Optics",
        "The power of a lens is defined as",
        "the reciprocal of its focal length",
        ["twice its focal length", "its focal length squared", "the ratio of image height to object height"],
        "The notes give P = 1/f, with lens power in dioptres.",
        1,
    ),
    (
        "Wave Optics & Polarization",
        "Dispersion of light is the separation of colours because",
        "refractive index varies with wavelength",
        ["frequency changes at a boundary", "light becomes longitudinal", "the speed of sound changes"],
        "The notes attribute dispersion and chromatic aberration to wavelength-dependent refractive index.",
        2,
    ),
    (
        "Wave Optics & Polarization",
        "Huygens' principle states that every point on a wavefront acts as",
        "a source of secondary wavelets",
        ["a node of zero displacement", "a polarizer", "a total reflector"],
        "The course outline lists Huygens' principle with interference and diffraction.",
        2,
    ),
    (
        "Wave Optics & Polarization",
        "Interference and diffraction of light provide evidence for",
        "the wave nature of light",
        ["the particle-only nature of light", "total internal reflection", "the Doppler effect"],
        "These are classic wave phenomena listed under wave optics.",
        1,
    ),
    (
        "Wave Optics & Polarization",
        "A Polaroid produces",
        "plane-polarized light",
        ["unpolarized white light only", "sound beats", "a total eclipse"],
        "The notes describe plane polarization using a Polaroid or calcite/tourmaline crystal.",
        1,
    ),
    (
        "Wave Optics & Polarization",
        "The velocity of light",
        "depends on the medium through which it travels",
        ["is the same in every medium", "is zero in glass", "equals the speed of sound in air"],
        "The lecture note states that light velocity depends on the medium.",
        1,
    ),
    (
        "Wave Optics & Polarization",
        "Light waves are",
        "electromagnetic and transverse",
        ["mechanical and longitudinal", "longitudinal sound waves", "unable to be polarized"],
        "Light needs no medium and can be polarized, so it is transverse electromagnetic radiation.",
        1,
    ),
    (
        "Wave Optics & Polarization",
        "Scattering of light refers to",
        "redirection of light by particles or irregularities",
        ["complete absorption with no re-emission", "a change of radio frequency", "formation of beats"],
        "The course outline lists scattering of light under optics.",
        2,
    ),
    (
        "Wave Optics & Polarization",
        "Optical instruments form images using",
        "lenses and/or mirrors",
        ["resonance tubes", "tuning forks", "Polaroid filters only"],
        "The outline includes thin lenses and optical instruments.",
        1,
    ),
]

# Each numeric template generates five variants from the source formulas.
NUMERIC = [
    {
        "topic": "Simple Harmonic Motion",
        "text": "A simple pendulum has length {l} m. Taking g = {g} m s⁻², its period is approximately",
        "unit": " s",
        "explain": "Use T = 2π√(l/g) with l = {l} m and g = {g} m s⁻²; T ≈ {value}.",
        "calc": lambda p: 2 * math.pi * math.sqrt(p["l"] / p["g"]),
        "params": [
            {"l": 0.25, "g": 9.8}, {"l": 0.49, "g": 9.8}, {"l": 1.0, "g": 9.8},
            {"l": 1.44, "g": 9.8}, {"l": 2.25, "g": 9.8},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "A simple pendulum of length {l} m oscillates with g = {g} m s⁻². Its frequency is approximately",
        "unit": " Hz",
        "explain": "Use f = (1/2π)√(g/l) with l = {l} m and g = {g} m s⁻²; f ≈ {value}.",
        "calc": lambda p: math.sqrt(p["g"] / p["l"]) / (2 * math.pi),
        "params": [
            {"l": 0.25, "g": 9.8}, {"l": 0.49, "g": 9.8}, {"l": 1.0, "g": 9.8},
            {"l": 1.44, "g": 9.8}, {"l": 2.25, "g": 9.8},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "A mass of {m} kg hangs from a spring of constant {k} N m⁻¹. The oscillation period is approximately",
        "unit": " s",
        "explain": "Use T = 2π√(m/k) with m = {m} kg and k = {k} N m⁻¹; T ≈ {value}.",
        "calc": lambda p: 2 * math.pi * math.sqrt(p["m"] / p["k"]),
        "params": [
            {"m": 0.2, "k": 80}, {"m": 0.5, "k": 50}, {"m": 1.0, "k": 100},
            {"m": 2.0, "k": 200}, {"m": 4.0, "k": 1600},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "For a spring-mass system with m = {m} kg and k = {k} N m⁻¹, the angular frequency is",
        "unit": " rad s⁻¹",
        "explain": "Use ω = √(k/m) with m = {m} kg and k = {k} N m⁻¹; ω ≈ {value}.",
        "calc": lambda p: math.sqrt(p["k"] / p["m"]),
        "params": [
            {"m": 0.2, "k": 80}, {"m": 0.5, "k": 50}, {"m": 1.0, "k": 100},
            {"m": 2.0, "k": 200}, {"m": 4.0, "k": 1600},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "A spring-mass oscillator has m = {m} kg and k = {k} N m⁻¹. Its frequency is approximately",
        "unit": " Hz",
        "explain": "Use f = (1/2π)√(k/m) with m = {m} kg and k = {k} N m⁻¹; f ≈ {value}.",
        "calc": lambda p: math.sqrt(p["k"] / p["m"]) / (2 * math.pi),
        "params": [
            {"m": 0.2, "k": 80}, {"m": 0.5, "k": 50}, {"m": 1.0, "k": 100},
            {"m": 2.0, "k": 200}, {"m": 4.0, "k": 1600},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "An SHM oscillator has mass {m} kg, angular frequency {omega} rad s⁻¹ and amplitude {a} m. Its total energy is",
        "unit": " J",
        "explain": "Use E = ½mω²a² with m = {m} kg, ω = {omega} rad s⁻¹ and a = {a} m; E ≈ {value}.",
        "calc": lambda p: 0.5 * p["m"] * p["omega"] ** 2 * p["a"] ** 2,
        "params": [
            {"m": 0.5, "omega": 10, "a": 0.1}, {"m": 0.5, "omega": 10, "a": 0.2},
            {"m": 1.0, "omega": 5, "a": 0.2}, {"m": 2.0, "omega": 4, "a": 0.1},
            {"m": 0.2, "omega": 20, "a": 0.05},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "An SHM oscillator has angular frequency {omega} rad s⁻¹ and amplitude {a} m. Its maximum speed is",
        "unit": " m s⁻¹",
        "explain": "Use vmax = ωa with ω = {omega} rad s⁻¹ and a = {a} m; vmax ≈ {value}.",
        "calc": lambda p: p["omega"] * p["a"],
        "params": [
            {"omega": 10, "a": 0.1}, {"omega": 10, "a": 0.2}, {"omega": 20, "a": 0.04},
            {"omega": 5, "a": 0.5}, {"omega": 8, "a": 0.25},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Simple Harmonic Motion",
        "text": "An SHM oscillator has angular frequency {omega} rad s⁻¹ and amplitude {a} m. Its maximum acceleration is",
        "unit": " m s⁻²",
        "explain": "Use amax = ω²a with ω = {omega} rad s⁻¹ and a = {a} m; amax ≈ {value}.",
        "calc": lambda p: p["omega"] ** 2 * p["a"],
        "params": [
            {"omega": 10, "a": 0.1}, {"omega": 10, "a": 0.2}, {"omega": 20, "a": 0.04},
            {"omega": 5, "a": 0.5}, {"omega": 8, "a": 0.25},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Wave Properties & Equations",
        "text": "A sinusoidal wave has angular frequency {omega} rad s⁻¹ and angular wave number {k} rad m⁻¹. Its speed is",
        "unit": " m s⁻¹",
        "explain": "Use v = ω/k with ω = {omega} rad s⁻¹ and k = {k} rad m⁻¹; v = {value}.",
        "calc": lambda p: p["omega"] / p["k"],
        "params": [
            {"omega": 100, "k": 5}, {"omega": 200, "k": 10}, {"omega": 300, "k": 6},
            {"omega": 400, "k": 8}, {"omega": 500, "k": 25},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Wave Properties & Equations",
        "text": "A wave has angular wave number k = {k} rad m⁻¹. Its wavelength is approximately",
        "unit": " m",
        "explain": "Use λ = 2π/k with k = {k} rad m⁻¹; λ ≈ {value}.",
        "calc": lambda p: 2 * math.pi / p["k"],
        "params": [
            {"k": 1}, {"k": 2}, {"k": 5}, {"k": 10}, {"k": 20},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Wave Properties & Equations",
        "text": "A wave of frequency {f} Hz has wavelength {lam} m. Its speed is",
        "unit": " m s⁻¹",
        "explain": "Use v = fλ with f = {f} Hz and λ = {lam} m; v = {value}.",
        "calc": lambda p: p["f"] * p["lam"],
        "params": [
            {"f": 50, "lam": 2}, {"f": 100, "lam": 1.5}, {"f": 200, "lam": 0.5},
            {"f": 256, "lam": 1.35}, {"f": 340, "lam": 1.0},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Wave Properties & Equations",
        "text": "A wave travels at {v} m s⁻¹ with wavelength {lam} m. Its frequency is",
        "unit": " Hz",
        "explain": "Use f = v/λ with v = {v} m s⁻¹ and λ = {lam} m; f ≈ {value}.",
        "calc": lambda p: p["v"] / p["lam"],
        "params": [
            {"v": 340, "lam": 1.0}, {"v": 340, "lam": 0.5}, {"v": 340, "lam": 2.0},
            {"v": 1500, "lam": 3.0}, {"v": 30, "lam": 0.6},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Wave Properties & Equations",
        "text": "A wave has frequency {f} Hz. Its period is approximately",
        "unit": " s",
        "explain": "Use T = 1/f with f = {f} Hz; T ≈ {value}.",
        "calc": lambda p: 1 / p["f"],
        "params": [
            {"f": 2}, {"f": 5}, {"f": 10}, {"f": 20}, {"f": 50},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Superposition, Interference & Diffraction",
        "text": "Two equal-amplitude waves of amplitude {A} m superpose with phase difference {phi}°. The resultant amplitude is approximately",
        "unit": " m",
        "explain": "Use AR = 2A cos(φ/2) with A = {A} m and φ = {phi}°; AR ≈ {value}.",
        "calc": lambda p: 2 * p["A"] * math.cos(math.radians(p["phi"]) / 2),
        "params": [
            {"A": 0.3, "phi": 0}, {"A": 0.3, "phi": 30}, {"A": 0.3, "phi": 60},
            {"A": 0.3, "phi": 90}, {"A": 0.3, "phi": 120},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Doppler Effect, Beats & Echoes",
        "text": "Two tuning forks of frequencies {f1} Hz and {f2} Hz sound together. The beat frequency is",
        "unit": " Hz",
        "explain": "Use fbeat = |f1 - f2| with f1 = {f1} Hz and f2 = {f2} Hz; fbeat = {value}.",
        "calc": lambda p: abs(p["f1"] - p["f2"]),
        "params": [
            {"f1": 206, "f2": 194}, {"f1": 256, "f2": 250}, {"f1": 300, "f2": 294},
            {"f1": 440, "f2": 435}, {"f1": 512, "f2": 500},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Sound Intensity & Perception",
        "text": "A sound source delivers {P} W uniformly over an area of {area} m². The intensity is",
        "unit": " W m⁻²",
        "explain": "Use I = P/A with P = {P} W and A = {area} m²; I = {value}.",
        "calc": lambda p: p["P"] / p["area"],
        "params": [
            {"P": 10, "area": 2}, {"P": 20, "area": 5}, {"P": 50, "area": 10},
            {"P": 100, "area": 4}, {"P": 5, "area": 0.5},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Sound Intensity & Perception",
        "text": "A sound has intensity 10{n} times the threshold I0. Its level in decibels is",
        "unit": " dB",
        "explain": "Use β = 10 log10(I/I0); with I/I0 = 10{n}, β = 10 log10(10{n}) = {value}.",
        "calc": lambda p: 10 * p["n"],
        "params": [{"n": 1}, {"n": 2}, {"n": 3}, {"n": 4}, {"n": 5}],
        "superscript_keys": ["n"],
        "difficulty": 2,
    },
    {
        "topic": "Sound Intensity & Perception",
        "text": "Two sounds differ in level by {beta} dB. The ratio of their intensities is",
        "unit": "",
        "explain": "Use β = 10 log10(I2/I1), so I2/I1 = 10^(β/10) = {value}.",
        "calc": lambda p: 10 ** (p["beta"] / 10),
        "params": [{"beta": 10}, {"beta": 20}, {"beta": 30}, {"beta": 40}, {"beta": 50}],
        "difficulty": 2,
    },
    {
        "topic": "Sound Intensity & Perception",
        "text": "Using v = 331√(1 + Tc/273), the speed of sound in air at {Tc} °C is approximately",
        "unit": " m s⁻¹",
        "explain": "Substitute Tc = {Tc} °C into v = 331√(1 + Tc/273); v ≈ {value}.",
        "calc": lambda p: 331 * math.sqrt(1 + p["Tc"] / 273),
        "params": [{"Tc": 0}, {"Tc": 10}, {"Tc": 20}, {"Tc": 27}, {"Tc": 40}],
        "difficulty": 2,
    },
    {
        "topic": "Sound Intensity & Perception",
        "text": "A solid has Young modulus {E} N m⁻² and density {rho} kg m⁻³. The speed of sound in it is approximately",
        "unit": " m s⁻¹",
        "explain": "Use v = √(E/ρ) with E = {E} N m⁻² and ρ = {rho} kg m⁻³; v ≈ {value}.",
        "calc": lambda p: math.sqrt(p["E"] / p["rho"]),
        "params": [
            {"E": 7.0e10, "rho": 2700}, {"E": 2.0e11, "rho": 7800}, {"E": 1.6e10, "rho": 2000},
            {"E": 9.0e10, "rho": 9000}, {"E": 4.0e10, "rho": 4000},
        ],
        "difficulty": 3,
    },
    {
        "topic": "Sound Intensity & Perception",
        "text": "A liquid has bulk modulus {B} N m⁻² and density {rho} kg m⁻³. The speed of sound in it is approximately",
        "unit": " m s⁻¹",
        "explain": "Use v = √(B/ρ) with B = {B} N m⁻² and ρ = {rho} kg m⁻³; v ≈ {value}.",
        "calc": lambda p: math.sqrt(p["B"] / p["rho"]),
        "params": [
            {"B": 2.19e9, "rho": 1000}, {"B": 2.0e9, "rho": 800}, {"B": 1.5e9, "rho": 750},
            {"B": 3.0e9, "rho": 1200}, {"B": 1.0e9, "rho": 500},
        ],
        "difficulty": 3,
    },
    {
        "topic": "Waves in Pipes & Resonance",
        "text": "An open pipe of length {l} m carries sound at {v} m s⁻¹. Its fundamental frequency is",
        "unit": " Hz",
        "explain": "For an open pipe use f0 = v/(2l) with v = {v} m s⁻¹ and l = {l} m; f0 ≈ {value}.",
        "calc": lambda p: p["v"] / (2 * p["l"]),
        "params": [
            {"v": 340, "l": 0.5}, {"v": 340, "l": 1.0}, {"v": 340, "l": 0.25},
            {"v": 340, "l": 2.0}, {"v": 340, "l": 0.8},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Waves in Pipes & Resonance",
        "text": "A closed pipe of length {l} m carries sound at {v} m s⁻¹. Its fundamental frequency is",
        "unit": " Hz",
        "explain": "For a closed pipe use f0 = v/(4l) with v = {v} m s⁻¹ and l = {l} m; f0 ≈ {value}.",
        "calc": lambda p: p["v"] / (4 * p["l"]),
        "params": [
            {"v": 340, "l": 0.5}, {"v": 340, "l": 1.0}, {"v": 340, "l": 0.25},
            {"v": 340, "l": 2.0}, {"v": 340, "l": 0.8},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Waves in Pipes & Resonance",
        "text": "In a resonance tube, successive resonances occur at {l1} m and {l2} m with a fork of {f} Hz. The speed of sound is",
        "unit": " m s⁻¹",
        "explain": "Use v = 2f(l2 - l1) with f = {f} Hz, l1 = {l1} m and l2 = {l2} m; v ≈ {value}.",
        "calc": lambda p: 2 * p["f"] * (p["l2"] - p["l1"]),
        "params": [
            {"f": 256, "l1": 0.325, "l2": 1.0}, {"f": 256, "l1": 0.30, "l2": 0.95},
            {"f": 300, "l1": 0.28, "l2": 0.85}, {"f": 400, "l1": 0.20, "l2": 0.62},
            {"f": 512, "l1": 0.16, "l2": 0.49},
        ],
        "difficulty": 2,
    },
    {
        "topic": "Geometrical Optics",
        "text": "Light passes from air into a medium of refractive index {eta} with incidence angle {i}°. Using η = sin i / sin r, the refraction angle is approximately",
        "unit": "°",
        "explain": "Rearrange Snell's law to r = arcsin(sin i / η) with i = {i}° and η = {eta}; r ≈ {value}.",
        "calc": lambda p: math.degrees(math.asin(math.sin(math.radians(p["i"])) / p["eta"])),
        "params": [
            {"eta": 1.5, "i": 30}, {"eta": 1.5, "i": 45}, {"eta": 1.5, "i": 60},
            {"eta": 1.33, "i": 30}, {"eta": 1.33, "i": 45},
        ],
        "difficulty": 3,
    },
    {
        "topic": "Geometrical Optics",
        "text": "A lens has focal length {f} m. Its power is",
        "unit": " D",
        "explain": "Use P = 1/f with f = {f} m; P = {value} dioptres.",
        "calc": lambda p: 1 / p["f"],
        "params": [{"f": 0.25}, {"f": 0.5}, {"f": 0.2}, {"f": 0.1}, {"f": 0.4}],
        "difficulty": 2,
    },
    {
        "topic": "Geometrical Optics",
        "text": "Light travels from a medium of refractive index {n1} into one of index {n2}. The critical angle is approximately",
        "unit": "°",
        "explain": "Use sin θc = n2/n1 with n1 = {n1} and n2 = {n2}; θc ≈ {value}.",
        "calc": lambda p: math.degrees(math.asin(p["n2"] / p["n1"])),
        "params": [
            {"n1": 1.5, "n2": 1.0}, {"n1": 1.33, "n2": 1.0}, {"n1": 2.0, "n2": 1.0},
            {"n1": 1.6, "n2": 1.0}, {"n1": 1.8, "n2": 1.0},
        ],
        "difficulty": 3,
    },
]


def make_questions():
    questions = []

    for topic, stem, correct, distractors, explanation, difficulty in CONCEPTUAL:
        options, correct_index = build_options(correct, distractors)
        questions.append(
            {
                "topic": topic,
                "text": stem,
                "options": options,
                "correct_index": correct_index,
                "explanation": explanation,
                "difficulty": difficulty,
            }
        )

    # Ten SHM templates use four parameter sets instead of five so that every
    # source formula is represented while the bank stays at exactly 200 items.
    four_variant_specs = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

    for spec_number, spec in enumerate(NUMERIC, start=1):
        parameter_sets = spec["params"][:4] if spec_number in four_variant_specs else spec["params"]
        for params in parameter_sets:
            display = {key: fmt(value) for key, value in params.items()}
            for key in spec.get("superscript_keys", []):
                display[key] = SUPERSCRIPT[int(params[key])]
            correct_value = spec["calc"](params)
            value_text = f"{fmt(correct_value)}{spec['unit']}"
            text = spec["text"].format(**display)
            explanation = spec["explain"].format(**display, value=value_text)
            options, correct_index = numeric_options(correct_value, spec["unit"])
            questions.append(
                {
                    "topic": spec["topic"],
                    "text": text,
                    "options": options,
                    "correct_index": correct_index,
                    "explanation": explanation,
                    "difficulty": spec["difficulty"],
                }
            )

    for index, question in enumerate(questions, start=1):
        question["id"] = f"{COURSE_ID}_{index:03d}"

    return questions


def validate(questions):
    texts = [q["text"] for q in questions]
    if len(set(texts)) != len(texts):
        raise ValueError("Duplicate question text detected")

    for q in questions:
        if not q["text"].strip():
            raise ValueError("Empty question text")
        if not (2 <= len(q["options"]) <= 6):
            raise ValueError("Bad option count")
        if len(set(q["options"])) != len(q["options"]):
            raise ValueError(f"Duplicate options in {q['id']}")
        if not (0 <= q["correct_index"] < len(q["options"])):
            raise ValueError(f"Bad correct_index in {q['id']}")
        if not q["explanation"].strip():
            raise ValueError("Empty explanation")
        lowered = " ".join([q["text"], *q["options"]]).lower()
        if "concept a" in lowered or "concept b" in lowered:
            raise ValueError(f"Placeholder wording in {q['id']}")


def main():
    questions = make_questions()
    validate(questions)

    if len(questions) != 200:
        raise ValueError(f"Expected 200 questions, generated {len(questions)}")

    payload = {
        "course_id": COURSE_ID,
        "course_name": COURSE_NAME,
        "version": VERSION,
        "sources": [
            "100level/second semester/phy104/PHY 104 complete.pdf",
            "100level/second semester/phy104/PHY 104 LECTURE NOTE(3)_013225.pdf",
        ],
        "source_note": (
            "New source-grounded practice MCQs generated from the two text-based PDFs. "
            "The image-only 'PHY 104 Questions.pdf' is not included; it needs OCR or "
            "manual transcription before its past questions can be added."
        ),
        "topics": TOPICS,
        "questions": questions,
    }

    OUT.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    by_topic = {}
    for q in questions:
        by_topic[q["topic"]] = by_topic.get(q["topic"], 0) + 1

    print(f"Wrote {OUT.relative_to(ROOT)}: {len(questions)} questions, version {VERSION}")
    for topic in TOPICS:
        print(f"  {topic}: {by_topic.get(topic, 0)}")


if __name__ == "__main__":
    main()
