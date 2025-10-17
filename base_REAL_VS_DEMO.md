# Real AI Separation vs Demo Mode

## 🚨 **Important: You're Currently Using DEMO Mode**

### **What You're Hearing Now (Demo Mode):**
- 🎵 **Vocals**: High-pitched sine wave (880Hz) - pure tone
- 🥁 **Drums**: Low-pitched square wave (220Hz) - harsh, digital sound  
- 🎸 **Bass**: Very low sawtooth wave (110Hz) - buzzy, rich harmonics
- 🎵 **Other**: Medium triangle wave (440Hz) - smooth, mellow tone

**These are NOT separated from your actual song** - they're just test tones to verify the system works.

## 🔄 **How to Get REAL AI Separation:**

### **Option 1: Use the Full AI API**

```bash
# Stop the demo API
pkill -f flask_api_simple.py

# Install AI dependencies (this may take time and space)
pip install torch torchaudio demucs librosa soundfile

# Start the REAL AI API
cd python_backend
python3 flask_api.py
```

**What this does:**
- Downloads the Demucs AI model (~500MB)
- Actually separates your audio into real vocals, drums, bass, other
- Takes 30 seconds to several minutes depending on song length
- Requires significant CPU/GPU power

### **Option 2: Test with Command Line (Real Separation)**

```bash
# Install dependencies
pip install demucs

# Separate a song directly
python3 -m demucs your_song.mp3

# Results will be in separated/htdemucs/your_song/
```

### **Option 3: Use Batch Processing Script**

```bash
# Process with the existing batch script
python3 batch_process.py /path/to/your/song.mp3 --output-dir ./results
```

## 🎯 **Current Demo vs Real Comparison:**

| Feature | Demo Mode (Current) | Real AI Mode |
|---------|-------------------|--------------|
| **Processing Time** | 6 seconds | 30 seconds - 5 minutes |
| **Output** | Test tones | Real separated audio |
| **CPU Usage** | Minimal | High |
| **Dependencies** | Just Flask | Torch, Demucs, etc. |
| **File Size** | Small | Large (models ~500MB) |
| **Purpose** | Test interface | Actual separation |

## 🧪 **To Test if Demo is Working Correctly:**

After restarting the API with my fixes, you should hear:

1. **Upload any audio file**
2. **Wait for processing**
3. **Play each stem - you should hear:**
   - 🎤 **Vocals**: Clean, high-pitched sine wave
   - 🥁 **Drums**: Harsh, digital square wave (sounds like old video game)
   - 🎸 **Bass**: Deep, buzzy sawtooth wave  
   - 🎵 **Other**: Smooth triangle wave

**If they all sound the same, there's still a bug in the demo.**

## 🚀 **Quick Test of Fixed Demo:**

```bash
# Restart API with fixes
pkill -f flask_api_simple.py
cd python_backend
python3 flask_api_simple.py

# Test in web demo - you should now hear 4 VERY different sounds
```

## 🎵 **What Real Separation Sounds Like:**

With the full AI (`flask_api.py`):
- 🎤 **Vocals**: Just the singer's voice, isolated
- 🥁 **Drums**: Just the drum kit (kick, snare, cymbals, etc.)
- 🎸 **Bass**: Just the bass guitar/synth bass lines
- 🎵 **Other**: Everything else (guitars, keyboards, strings, etc.)

## ⚡ **Quick Decision Guide:**

### **Want to test the interface?** 
→ Use demo mode (current setup) - should have 4 different test sounds

### **Want real separation?**
→ Switch to `flask_api.py` and install AI dependencies

### **Want to see real results quickly?**
→ Use command line: `python3 -m demucs your_song.mp3`

## 🔧 **Current Issue Resolution:**

The fact that all stems sound the same suggests the demo tone generation isn't working properly. I've just fixed this with:

1. **More distinct frequencies** (880Hz, 440Hz, 220Hz, 110Hz)
2. **Different waveforms** (sine, triangle, square, sawtooth)
3. **Better logging** to see what's being generated

**Restart the API and test again - you should now hear 4 completely different sounds.**
