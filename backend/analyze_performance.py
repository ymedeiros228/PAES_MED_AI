import cProfile
import pstats
from .main import main_function

def analyze_backend():
    profiler = cProfile.Profile()
    profiler.enable()
    
    # Call the main function of your backend
    main_function()
    
    profiler.disable()
    ps = pstats.Stats(profiler)
    ps.sort_stats('cumulative').print_stats(10)

if __name__ == "__main__":
    analyze_backend()
