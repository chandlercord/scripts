'''
homework_5_solution_program.py

'''

import homework_5_solution_module

def Run():
    
    name = AskForFileName()
    print name

    all_file_contents = ReadFileContents (name)
    head_list = BuildHeadList (all_file_contents)
    atom_list = BuildAtomList (all_file_contents)
    tail_list = BuildTailList (all_file_contents)
    WriteNewFile (head_list, atom_list, tail_list)
    
Run ()
