# AI Song Splitter - Demo Webpage

A modern, interactive web interface to test the AI-powered audio separation functionality.

## Features

- 🎵 **Drag & Drop Upload** - Easy file upload with drag and drop support
- 🤖 **Real-time Processing** - Live progress tracking with visual feedback
- 🎧 **Audio Playback** - Play separated stems directly in the browser
- 📊 **Quality Analysis** - View detailed quality metrics for each separation
- 📥 **Download Stems** - Download individual separated audio tracks
- 📋 **Processing History** - Track all your separation jobs
- 🔄 **API Health Check** - Monitor backend API status

## Supported Audio Formats

- MP3 (.mp3)
- WAV (.wav)
- M4A (.m4a)
- FLAC (.flac)
- AAC (.aac)

Maximum file size: 50MB

## Quick Start

### 1. Start the Flask API Backend

First, make sure the Python backend is running:

```bash
cd python_backend
python flask_api.py
```

The API should be running on `http://localhost:5000`

### 2. Start the Demo Web Server

```bash
cd demo_web
python server.py
```

The demo webpage will be available at `http://localhost:8080`

### 3. Test the Functionality

1. **Upload Audio File**: Drag and drop or click to select an audio file
2. **Monitor Progress**: Watch the real-time processing status
3. **Play Results**: Use the built-in audio player to preview separated stems
4. **Download**: Save individual stems to your computer
5. **View Metrics**: Check quality analysis results

## How It Works

### Processing Steps

1. **Upload** - File is uploaded to the Flask API server
2. **AI Separation** - Demucs AI model separates the audio into stems:
   - 🎤 Vocals
   - 🥁 Drums  
   - 🎸 Bass
   - 🎵 Other instruments
3. **Quality Analysis** - Analyzes separation quality with metrics like:
   - Signal-to-Noise Ratio
   - Spectral Centroid
   - RMS Energy
   - Zero Crossing Rate

### API Endpoints Used

- `POST /api/upload` - Upload audio file
- `POST /api/separate/{job_id}` - Start separation process
- `GET /api/status/{job_id}` - Check processing status
- `GET /api/download/{job_id}/{stem}` - Download separated stem
- `GET /api/jobs` - List all processing jobs
- `GET /api/health` - Check API health

## Troubleshooting

### Common Issues

**API Offline Error**
- Make sure the Flask API is running on port 5000
- Check that all Python dependencies are installed

**Upload Fails**
- Verify file format is supported
- Check file size is under 50MB
- Ensure stable internet connection

**Processing Stuck**
- Check Flask API logs for errors
- Restart the API server if needed
- Verify sufficient disk space for processing

**Audio Won't Play**
- Check browser audio permissions
- Try a different browser (Chrome/Firefox recommended)
- Verify the stem file was generated successfully

### Browser Compatibility

Tested and supported browsers:
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## File Structure

```
demo_web/
├── index.html          # Main demo webpage
├── script.js          # JavaScript functionality
├── server.py          # Simple HTTP server
└── README.md          # This file
```

## Development

To modify the demo:

1. Edit `index.html` for UI changes
2. Edit `script.js` for functionality changes
3. Restart the server to see changes

The demo uses:
- **TailwindCSS** for styling
- **Font Awesome** for icons
- **Vanilla JavaScript** for functionality
- **HTML5 Audio API** for playback

## Tips for Best Results

- Use high-quality audio files (WAV/FLAC preferred)
- Avoid heavily compressed MP3 files
- Songs with clear vocal/instrument separation work best
- Processing time depends on file length and system performance

## Support

If you encounter issues:
1. Check the browser console for JavaScript errors
2. Verify the Flask API logs for backend errors
3. Ensure all dependencies are properly installed
4. Test with a smaller audio file first
