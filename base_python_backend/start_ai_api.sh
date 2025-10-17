#!/bin/bash

echo "🤖 Starting AI Flask API with Virtual Environment"
echo "================================================="

# Navigate to project root
cd /home/igris/sandesh_2/song_splitter

# Activate virtual environment
echo "🔄 Activating virtual environment..."
source ai_env/bin/activate

# Verify environment
echo "📦 Checking dependencies..."
python3 -c "
try:
    import torch, demucs, librosa, soundfile, torchcodec
    print('✅ All AI dependencies found')
    print(f'   PyTorch: {torch.__version__}')
    print(f'   Device: {\"CUDA\" if torch.cuda.is_available() else \"CPU\"}')
except ImportError as e:
    print(f'❌ Missing: {e}')
    exit(1)
"

if [ $? -ne 0 ]; then
    echo "❌ Dependencies missing. Installing..."
    pip install torchcodec
fi

# Start Flask API
echo "🚀 Starting AI Flask API..."
cd python_backend
export PYTHONPATH="/home/igris/sandesh_2/song_splitter/ai_env/lib/python3.13/site-packages:$PYTHONPATH"
python3 flask_api.py
