project('examples', 'c',
  version : '0.1',
  default_options : ['warning_level=3'])

src_dir = 'shared_var'  # Directory containing your C files

# Find all C files in the src directory
sources = run_command('ls', src_dir, check: true).stdout().strip().split('\n')

# Iterate over each source file
foreach src : sources
  exe_name = src.split('/')[-1].split('.')[0]  # Extract filename without extension
  executable(src_dir + '_' + exe_name, src_dir + '/' + src,  # Create an executable from each C file
             # ... other options as needed ...
  ) 
endforeach
