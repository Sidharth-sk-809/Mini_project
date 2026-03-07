import sys
import os
import uvicorn

# Ensure the app directory is in the Python path
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

if __name__ == '__main__':
    # Disable reload in production (Render environment)
    reload = os.getenv('RENDER') is None
    uvicorn.run('app.main:app', host='0.0.0.0', port=8000, reload=reload)
