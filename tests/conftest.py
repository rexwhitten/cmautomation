import sys
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Ensure the project root is in sys.path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
