project('examples', 'c',
  version : '0.1',
  default_options : ['warning_level=3'])

src_dirs = ['shared_var', 'thread_pool']  # Directory containing your C files

foreach src_dir: src_dirs
  sources = run_command('ls', src_dir, check: true).stdout().strip().split('\n')
  foreach src : sources
    exe_name = src.split('/')[-1].split('.')[0]  # Extract filename without extension
    executable(src_dir + '_' + exe_name, [src_dir + '/' + src, 'thpool.c'],  # Create an executable from each C file
    )
  endforeach
endforeach

executable('privileges', 'privileges.c')
