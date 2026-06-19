import os
from PIL import Image

def fix_pngs(base_dir):
    count = 0
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file.endswith('.png'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'rb') as f:
                        header = f.read(4)
                    
                    # Check if it's NOT a true PNG header
                    if header != b'\x89PNG':
                        print(f"Fixing: {file_path}")
                        img = Image.open(file_path)
                        img.save(file_path, 'PNG')
                        count += 1
                except Exception as e:
                    print(f"Error processing {file_path}: {e}")
    
    print(f"Successfully converted {count} invalid images to true PNG format!")

if __name__ == "__main__":
    res_dir = r"c:\Users\hmanc\OLX\app\android\app\src\main\res"
    fix_pngs(res_dir)
