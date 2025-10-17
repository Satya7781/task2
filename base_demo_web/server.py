#!/usr/bin/env python3
"""
Simple HTTP server for the Song Splitter demo webpage
"""

import http.server
import socketserver
import webbrowser
import os
import sys
from pathlib import Path

# Configuration
PORT = 8080
DEMO_DIR = Path(__file__).parent

class CORSHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS support"""
    
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

def start_server():
    """Start the HTTP server for the demo webpage"""
    
    # Change to demo directory
    os.chdir(DEMO_DIR)
    
    # Create server
    with socketserver.TCPServer(("", PORT), CORSHTTPRequestHandler) as httpd:
        print(f"🚀 Song Splitter Demo Server")
        print(f"📁 Serving from: {DEMO_DIR.absolute()}")
        print(f"🌐 Server running at: http://localhost:{PORT}")
        print(f"🎵 Make sure the Flask API is running on http://localhost:5000")
        print(f"⏹️  Press Ctrl+C to stop the server")
        print("-" * 60)
        
        try:
            # Try to open browser automatically
            webbrowser.open(f'http://localhost:{PORT}')
        except:
            pass
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped by user")
            sys.exit(0)

if __name__ == "__main__":
    start_server()
